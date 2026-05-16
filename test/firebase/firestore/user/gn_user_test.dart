import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

// ignore: subtype_of_sealed_class
class _MockDoc extends Mock implements DocumentSnapshot<Object?> {}

void main() {
  test('toMap includes tombstone fields', () {
    final deletedAt = DateTime(2026, 5, 10);
    final user = GNUser(
      id: 'u1',
      displayName: 'Tai',
      phoneNumber: '090',
      email: 'tai@example.com',
      photoUrl: 'https://avatar',
      role: 'user',
      fcmToken: 'token',
      deleted: true,
      deletedAt: deletedAt,
    );

    final map = user.toMap();

    expect(map[GNUser.deletedKey], true);
    expect((map[GNUser.deletedAtKey] as Timestamp).toDate(), deletedAt);
  });

  test('fromFireStore defaults tombstone fields for legacy docs', () {
    final doc = _MockDoc();
    when(() => doc.id).thenReturn('u1');
    when(() => doc.data()).thenReturn(<String, dynamic>{
      GNUser.displayNameKey: 'Tai',
      GNUser.roleKey: 'user',
    });

    final user = GNUser.fromFireStore(doc);

    expect(user.deleted, false);
    expect(user.deletedAt, isNull);
  });

  test('effectiveDisplayName handles deleted and null names', () {
    const active = GNUser(
      id: 'u1',
      displayName: 'Tai',
      phoneNumber: null,
      email: null,
      photoUrl: null,
      role: 'user',
      fcmToken: '',
    );
    final deleted = active.copyWith(deleted: true);
    const unnamed = GNUser(
      id: 'u2',
      displayName: null,
      phoneNumber: null,
      email: null,
      photoUrl: null,
      role: 'user',
      fcmToken: '',
    );

    expect(active.effectiveDisplayName, 'Tai');
    expect(deleted.effectiveDisplayName, 'Tai (đã xoá)');
    expect(unnamed.effectiveDisplayName, 'Người chơi');
  });

  test('copyWith and role/deleted getters', () {
    const user = GNUser(
      id: 'u1',
      displayName: 'Admin',
      phoneNumber: null,
      email: null,
      photoUrl: null,
      role: 'admin',
      fcmToken: '',
      deleted: true,
    );

    final activeUser = user.copyWith(deleted: false);
    final renamedUser = activeUser.copyWith(displayName: 'User');

    expect(user.isDeleted, true);
    expect(user.isAdmin, true);
    expect(user.isUser, false);
    expect(activeUser.deleted, false);
    expect(renamedUser.isUser, false);
  });
}
