import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/api/api_client.dart';
import 'package:pes_arena/data/repositories/api/api_user_repository.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';

import '../../../api/fake_api.dart';

class _MockAuth extends Mock implements GNAuth {}

// ignore: subtype_of_sealed_class
class _MockUser extends Mock implements User {}

void main() {
  late FakeApi api;
  late _MockAuth auth;
  late _MockUser firebaseUser;
  XFile? picked;

  ApiUserRepository repo() => ApiUserRepository(
    client: api.client(),
    auth: auth,
    pickAvatar: () async => picked,
  );

  setUp(() {
    api = FakeApi();
    auth = _MockAuth();
    firebaseUser = _MockUser();
    picked = null;
    when(() => auth.currentUser).thenReturn(firebaseUser);
    when(() => firebaseUser.updatePhotoURL(any())).thenAnswer((_) async {});
    when(() => firebaseUser.updateDisplayName(any())).thenAnswer((_) async {});
    when(() => firebaseUser.delete()).thenAnswer((_) async {});
  });

  test('signOut and changePassword stay on Firebase Auth', () async {
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(() => auth.changePassword('a', 'b')).thenAnswer((_) async {});

    await repo().signOut();
    await repo().changePassword('a', 'b');

    verify(() => auth.signOut()).called(1);
    verify(() => auth.changePassword('a', 'b')).called(1);
    expect(api.requests, isEmpty);
  });

  test('ensureCurrentUser bootstraps from the Firebase profile', () async {
    when(() => firebaseUser.displayName).thenReturn('Tai');
    when(() => firebaseUser.email).thenReturn('t@x.dev');
    when(() => firebaseUser.phoneNumber).thenReturn(null);
    when(() => firebaseUser.photoURL).thenReturn('https://p');
    api.on('POST', '/v1/me/bootstrap', userJson('u1', name: 'Tai'));

    final user = await repo().ensureCurrentUser(firebaseUser);

    expect(user.displayName, 'Tai');
    expect(api.lastBody, {
      'displayName': 'Tai',
      'email': 't@x.dev',
      'phoneNumber': null,
      'photoUrl': 'https://p',
    });
  });

  test('loadProfile and getUser', () async {
    api.on('GET', '/v1/me', userJson('me'));
    api.on('GET', '/v1/users/u2', userJson('u2'));
    api.error('GET', '/v1/users/gone', 404, 'not_found');
    api.error('GET', '/v1/users/err', 500, 'internal');

    expect((await repo().loadProfile()).id, 'me');
    expect((await repo().getUser('u2'))?.id, 'u2');
    expect(await repo().getUser('gone'), isNull);
    await expectLater(repo().getUser('err'), throwsA(isA<ApiException>()));
  });

  test('getUsersByIds and createPlaceholderUser', () async {
    api.on('POST', '/v1/users/batch', {
      'users': [userJson('a')],
    });
    api.on('POST', '/v1/users/placeholders', {
      ...userJson('placeholder_x', name: 'Guest'),
      'isPlaceholder': true,
    });

    expect((await repo().getUsersByIds(['a'])).keys, ['a']);
    final guest = await repo().createPlaceholderUser(displayName: 'Guest');
    expect(guest.isPlaceholder, isTrue);
    expect(api.lastBody, {'displayName': 'Guest'});
  });

  test('updateProfile sends only non-empty fields', () async {
    api.on('PATCH', '/v1/me', userJson('me'), status: 200);

    await repo().updateProfile(
      displayName: 'New',
      phoneNumber: '',
      email: null,
    );

    expect(api.lastBody, {'displayName': 'New'});
    verify(() => firebaseUser.updateDisplayName('New')).called(1);

    await repo().updateProfile(phoneNumber: '090', email: 'e@x.dev');
    expect(api.lastBody, {'phoneNumber': '090', 'email': 'e@x.dev'});
    verifyNever(() => firebaseUser.updateDisplayName(null));
  });

  test(
    'deleteAccount removes the backend profile, then Firebase user',
    () async {
      api.on('DELETE', '/v1/me', null, status: 204);

      await repo().deleteAccount();

      expect(api.last.method, 'DELETE');
      verify(() => firebaseUser.delete()).called(1);
    },
  );

  test('deleteAccount requires a signed-in user', () async {
    when(() => auth.currentUser).thenReturn(null);

    await expectLater(repo().deleteAccount(), throwsException);
    expect(api.requests, isEmpty);
  });

  group('avatar', () {
    test('cancelled pick does nothing', () async {
      await repo().changeAvatar();
      expect(api.requests, isEmpty);
    });

    test('rejects files over 5 MB', () async {
      picked = XFile.fromData(
        Uint8List(ApiUserRepository.maxAvatarBytes + 1),
        name: 'big.png',
      );

      await expectLater(repo().changeAvatar(), throwsException);
      expect(api.requests, isEmpty);
    });

    test('uploads and mirrors the URL to Firebase Auth', () async {
      picked = XFile.fromData(
        Uint8List.fromList([1, 2]),
        path: '/photos/a.png',
      );
      api.on('PUT', '/v1/me/avatar', {
        ...userJson('me'),
        'photoUrl': 'https://api.test/avatars/a.png',
      });

      await repo().changeAvatar();

      expect(api.last.body, contains('filename="a.png"'));
      verify(
        () => firebaseUser.updatePhotoURL('https://api.test/avatars/a.png'),
      ).called(1);
    });

    test('falls back to a default filename', () async {
      picked = XFile.fromData(Uint8List.fromList([1]));
      api.on('PUT', '/v1/me/avatar', userJson('me'));

      await repo().changeAvatar();

      expect(api.last.body, contains('filename="avatar.jpg"'));
      verify(() => firebaseUser.updatePhotoURL(null)).called(1);
    });

    test('deleteAvatar clears it on both sides', () async {
      api.on('DELETE', '/v1/me/avatar', userJson('me'));

      await repo().deleteAvatar();

      expect(api.last.url.path, '/v1/me/avatar');
      verify(() => firebaseUser.updatePhotoURL(null)).called(1);
    });
  });

  test('search, globally and within a group', () async {
    api.on('GET', '/v1/users/search', [userJson('a')]);

    expect((await repo().searchUser('ta')).single.id, 'a');
    expect(api.last.url.queryParameters, {'q': 'ta'});

    await repo().searchUserByGroup('g1', 'ta');
    expect(api.last.url.queryParameters, {'q': 'ta', 'groupId': 'g1'});
  });
}
