import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/data/repositories/esport/esport_league_repository_impl.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/injection_container.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late EsportLeagueRepositoryImpl repo;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    getIt.registerSingleton<GNFirestore>(GNFirestore(firestore));
    repo = EsportLeagueRepositoryImpl();
  });

  tearDown(() => getIt.reset());

  test('getLeaguesByOwnerId delegates to firestore query', () async {
    await _createLeague('L1', ownerId: 'owner', participants: ['owner']);

    final leagues = await repo.getLeaguesByOwnerId('owner');

    expect(leagues.single.id, 'L1');
  });

  test(
    'transferLeagueOwnership validates participant and updates owner',
    () async {
      await _createLeague(
        'L1',
        ownerId: 'owner',
        participants: ['owner', 'u1'],
      );

      await repo.transferLeagueOwnership(leagueId: 'L1', newOwnerId: 'u1');

      final snap = await firestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .get();
      expect(snap.data()?[GNEsportLeague.fieldOwnerId], 'u1');
    },
  );

  test('transferLeagueOwnership rejects missing league', () async {
    expect(
      () => repo.transferLeagueOwnership(leagueId: 'missing', newOwnerId: 'u1'),
      throwsException,
    );
  });

  test('transferLeagueOwnership rejects non-participant', () async {
    await _createLeague('L1', ownerId: 'owner', participants: ['owner']);

    expect(
      () => repo.transferLeagueOwnership(leagueId: 'L1', newOwnerId: 'u1'),
      throwsException,
    );
  });
}

Future<void> _createLeague(
  String id, {
  required String ownerId,
  required List<String> participants,
}) async {
  final now = Timestamp.fromDate(DateTime(2026, 5, 10));
  final firestore = getIt<GNFirestore>().firestore;
  await firestore.collection(GNEsportGroup.collectionName).doc('G1').set({
    GNEsportGroup.groupNameKey: 'Group',
    GNEsportGroup.ownerIdKey: ownerId,
    GNEsportGroup.membersKey: participants,
    GNEsportGroup.deactivatedMembersKey: [],
    GNEsportGroup.descriptionKey: '',
    GNEsportGroup.createdAtKey: now,
    GNEsportGroup.updatedAtKey: now,
    GNEsportGroup.statusKey: 'active',
  });
  await firestore.collection(GNEsportLeague.collectionName).doc(id).set({
    GNEsportLeague.fieldOwnerId: ownerId,
    GNEsportLeague.fieldGroupId: 'G1',
    GNEsportLeague.fieldName: 'League',
    GNEsportLeague.fieldStartDate: now,
    GNEsportLeague.fieldIsActive: true,
    GNEsportLeague.fieldDescription: '',
    GNEsportLeague.fieldParticipants: participants,
  });
}
