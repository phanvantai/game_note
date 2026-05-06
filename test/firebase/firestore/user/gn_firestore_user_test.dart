import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/gn_firestore_user.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/injection_container.dart';

class _MockGNAuth extends Mock implements GNAuth {}

// ignore: subtype_of_sealed_class
class _MockFirebaseUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GNFirestore fs;
  late _MockGNAuth mockAuth;
  late _MockFirebaseUser mockUser;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fs = GNFirestore(fakeFirestore);
    mockAuth = _MockGNAuth();
    mockUser = _MockFirebaseUser();
    when(() => mockUser.uid).thenReturn('owner');
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    getIt.registerSingleton<GNAuth>(mockAuth);
  });

  tearDown(() => getIt.reset());

  Future<void> setupGroupDoc({
    List<String> members = const [],
    List<String> deactivatedMembers = const [],
    String groupId = 'G1',
  }) async {
    await fakeFirestore
        .collection(GNEsportGroup.collectionName)
        .doc(groupId)
        .set({
      GNEsportGroup.groupNameKey: 'Nhóm test',
      GNEsportGroup.ownerIdKey: 'owner',
      GNEsportGroup.membersKey: members,
      GNEsportGroup.deactivatedMembersKey: deactivatedMembers,
      GNEsportGroup.descriptionKey: '',
      GNEsportGroup.createdAtKey: Timestamp.now(),
      GNEsportGroup.updatedAtKey: Timestamp.now(),
      GNEsportGroup.statusKey: 'active',
    });
  }

  Future<void> setupUserDoc(String userId, String displayName) async {
    await fakeFirestore
        .collection(GNUser.collectionName)
        .doc(userId)
        .set({
      GNUser.displayNameKey: displayName,
      GNUser.emailKey: null,
      GNUser.phoneNumberKey: null,
      GNUser.photoUrlKey: null,
      GNUser.roleKey: 'user',
    });
  }

  group('searchUserByGroup — deactivated filter', () {
    test('loại deactivated member khỏi kết quả tìm kiếm', () async {
      await setupGroupDoc(
        members: ['owner', 'u1', 'u2'],
        deactivatedMembers: ['u2'],
      );
      await setupUserDoc('u1', 'Hùng');
      await setupUserDoc('u2', 'Hùng Deactivated');

      final results = await fs.searchUserByGroup('G1', 'Hùng');

      final ids = results.map((u) => u.id).toList();
      expect(ids, contains('u1'));
      expect(ids, isNot(contains('u2')));
    });

    test('trả về active member nếu không có ai bị deactivate', () async {
      await setupGroupDoc(
        members: ['owner', 'u1'],
        deactivatedMembers: [],
      );
      await setupUserDoc('u1', 'Tuấn');

      final results = await fs.searchUserByGroup('G1', 'Tuấn');

      expect(results.map((u) => u.id), contains('u1'));
    });
  });
}
