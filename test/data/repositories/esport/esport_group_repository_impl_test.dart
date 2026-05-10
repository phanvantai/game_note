import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/data/repositories/esport/esport_group_repository_impl.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/injection_container.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late EsportGroupRepositoryImpl repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    getIt.registerSingleton<GNFirestore>(GNFirestore(firestore));
    repo = EsportGroupRepositoryImpl();
  });

  tearDown(() => getIt.reset());

  test('getGroupsByOwnerId delegates to firestore query', () async {
    await _createGroup('G1', ownerId: 'owner', members: ['owner']);

    final groups = await repo.getGroupsByOwnerId('owner');

    expect(groups.single.id, 'G1');
  });

  test(
    'transferGroupOwnership validates membership and updates owner',
    () async {
      await _createGroup('G1', ownerId: 'owner', members: ['owner', 'u1']);

      await repo.transferGroupOwnership(groupId: 'G1', newOwnerId: 'u1');

      final snap = await firestore
          .collection(GNEsportGroup.collectionName)
          .doc('G1')
          .get();
      expect(snap.data()?[GNEsportGroup.ownerIdKey], 'u1');
    },
  );

  test('transferGroupOwnership rejects missing group', () async {
    expect(
      () => repo.transferGroupOwnership(groupId: 'missing', newOwnerId: 'u1'),
      throwsException,
    );
  });

  test('transferGroupOwnership rejects non-member', () async {
    await _createGroup('G1', ownerId: 'owner', members: ['owner']);

    expect(
      () => repo.transferGroupOwnership(groupId: 'G1', newOwnerId: 'u1'),
      throwsException,
    );
  });

  test('deactivateGroup delegates to firestore update', () async {
    await _createGroup('G1', ownerId: 'owner', members: ['owner']);

    await repo.deactivateGroup('G1');

    final snap = await firestore
        .collection(GNEsportGroup.collectionName)
        .doc('G1')
        .get();
    expect(snap.data()?[GNEsportGroup.statusKey], 'inactive');
  });
}

Future<void> _createGroup(
  String id, {
  required String ownerId,
  required List<String> members,
}) {
  final now = Timestamp.fromDate(DateTime(2026, 5, 10));
  return getIt<GNFirestore>().firestore
      .collection(GNEsportGroup.collectionName)
      .doc(id)
      .set({
        GNEsportGroup.groupNameKey: 'Group',
        GNEsportGroup.ownerIdKey: ownerId,
        GNEsportGroup.membersKey: members,
        GNEsportGroup.deactivatedMembersKey: [],
        GNEsportGroup.descriptionKey: '',
        GNEsportGroup.createdAtKey: now,
        GNEsportGroup.updatedAtKey: now,
        GNEsportGroup.statusKey: 'active',
      });
}
