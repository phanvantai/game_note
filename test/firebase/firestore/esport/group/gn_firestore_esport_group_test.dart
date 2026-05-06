import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_firestore_esport_group.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GNFirestore fs;

  Future<DocumentReference<Map<String, dynamic>>> createGroup({
    List<String> members = const ['owner', 'u1'],
    List<String> deactivatedMembers = const [],
  }) async {
    return fakeFirestore.collection(GNEsportGroup.collectionName).add({
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

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fs = GNFirestore(fakeFirestore);
  });

  group('toggleMemberDeactivation', () {
    test('deactivate: true → thêm userId vào deactivatedMembers', () async {
      final ref = await createGroup(members: ['owner', 'u1']);
      final groupId = ref.id;

      await fs.toggleMemberDeactivation(
        groupId: groupId,
        userId: 'u1',
        deactivate: true,
      );

      final snap = await fakeFirestore
          .collection(GNEsportGroup.collectionName)
          .doc(groupId)
          .get();
      final deactivated = List<String>.from(
          snap.data()?[GNEsportGroup.deactivatedMembersKey] ?? []);
      expect(deactivated, contains('u1'));
    });

    test('deactivate: false → xoá userId khỏi deactivatedMembers', () async {
      final ref = await createGroup(
        members: ['owner', 'u1'],
        deactivatedMembers: ['u1'],
      );
      final groupId = ref.id;

      await fs.toggleMemberDeactivation(
        groupId: groupId,
        userId: 'u1',
        deactivate: false,
      );

      final snap = await fakeFirestore
          .collection(GNEsportGroup.collectionName)
          .doc(groupId)
          .get();
      final deactivated = List<String>.from(
          snap.data()?[GNEsportGroup.deactivatedMembersKey] ?? []);
      expect(deactivated, isNot(contains('u1')));
    });
  });

  group('removeMemberFromGroup', () {
    test('xoá userId khỏi cả members và deactivatedMembers', () async {
      final ref = await createGroup(
        members: ['owner', 'u1'],
        deactivatedMembers: ['u1'],
      );
      final groupId = ref.id;

      await fs.removeMemberFromGroup(groupId: groupId, memberId: 'u1');

      final snap = await fakeFirestore
          .collection(GNEsportGroup.collectionName)
          .doc(groupId)
          .get();
      final members = List<String>.from(
          snap.data()?[GNEsportGroup.membersKey] ?? []);
      final deactivated = List<String>.from(
          snap.data()?[GNEsportGroup.deactivatedMembersKey] ?? []);
      expect(members, isNot(contains('u1')));
      expect(deactivated, isNot(contains('u1')));
    });

    test('xoá member active (không trong deactivated) chỉ xoá khỏi members',
        () async {
      final ref = await createGroup(members: ['owner', 'u1']);
      final groupId = ref.id;

      await fs.removeMemberFromGroup(groupId: groupId, memberId: 'u1');

      final snap = await fakeFirestore
          .collection(GNEsportGroup.collectionName)
          .doc(groupId)
          .get();
      final members = List<String>.from(
          snap.data()?[GNEsportGroup.membersKey] ?? []);
      expect(members, isNot(contains('u1')));
      expect(members, contains('owner'));
    });
  });
}
