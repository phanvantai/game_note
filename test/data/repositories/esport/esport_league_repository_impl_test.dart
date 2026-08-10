import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/data/repositories/esport/esport_league_repository_impl.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
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

  test(
    'updateMatchAtomically delegates mutable fields and optimistic version',
    () async {
      final version = Timestamp.fromDate(DateTime(2026, 5, 10, 8));
      final matchRef = firestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportMatch.collectionName)
          .doc('M1');
      final stats = firestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName);
      await matchRef.set({
        GNEsportMatch.fieldHomeTeamId: 'home',
        GNEsportMatch.fieldAwayTeamId: 'away',
        GNEsportMatch.fieldHomeScore: 0,
        GNEsportMatch.fieldAwayScore: 0,
        GNEsportMatch.fieldDate: Timestamp.fromDate(DateTime(2026, 5, 10)),
        GNEsportMatch.fieldIsFinished: false,
        GNEsportMatch.fieldLeagueId: 'L1',
        GNEsportMatch.fieldMatchCost: 50000,
        GNEsportMatch.fieldCostPerGoal: 5000,
        GNEsportMatch.fieldUpdatedAt: version,
      });
      await stats
          .doc('random-home-stat-41')
          .set(_statMap(leagueId: 'L1', userId: 'home'));
      await stats
          .doc('random-away-stat-83')
          .set(_statMap(leagueId: 'L1', userId: 'away'));

      final submitted = GNEsportMatch(
        id: 'M1',
        homeTeamId: 'home',
        awayTeamId: 'away',
        homeScore: 4,
        awayScore: 2,
        date: DateTime(2026, 5, 10),
        isFinished: true,
        leagueId: 'L1',
        matchCost: 90000,
        costPerGoal: 12000,
        updatedAt: version,
      );

      await repo.updateMatchAtomically(submitted);

      final match = (await matchRef.get()).data()!;
      expect(match[GNEsportMatch.fieldHomeScore], 4);
      expect(match[GNEsportMatch.fieldAwayScore], 2);
      expect(match[GNEsportMatch.fieldIsFinished], true);
      expect(match[GNEsportMatch.fieldMatchCost], 90000);
      expect(match[GNEsportMatch.fieldCostPerGoal], 12000);
      expect(match[GNEsportMatch.fieldUpdatedAt], isA<Timestamp>());
      expect(match[GNEsportMatch.fieldUpdatedAt], isNot(version));

      expect((await stats.doc('random-home-stat-41').get()).data(), {
        ..._statMap(leagueId: 'L1', userId: 'home'),
        GNEsportLeagueStat.fieldMatchesPlayed: 1,
        GNEsportLeagueStat.fieldGoals: 4,
        GNEsportLeagueStat.fieldGoalsConceded: 2,
        GNEsportLeagueStat.fieldWins: 1,
      });
      expect((await stats.doc('random-away-stat-83').get()).data(), {
        ..._statMap(leagueId: 'L1', userId: 'away'),
        GNEsportLeagueStat.fieldMatchesPlayed: 1,
        GNEsportLeagueStat.fieldGoals: 2,
        GNEsportLeagueStat.fieldGoalsConceded: 4,
        GNEsportLeagueStat.fieldLosses: 1,
      });

      await expectLater(
        repo.updateMatchAtomically(submitted),
        throwsA(isA<ConcurrentMatchUpdateException>()),
      );
    },
  );

  test('listenForLeagueUpdated emits null after league deletion', () async {
    await _createLeague('L1', ownerId: 'owner', participants: ['owner']);
    final iterator = StreamIterator<GNEsportLeague?>(
      repo.listenForLeagueUpdated('L1'),
    );

    try {
      expect(await iterator.moveNext(), true);
      expect(iterator.current?.id, 'L1');

      await firestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .delete();

      expect(await iterator.moveNext(), true);
      expect(iterator.current, isNull);
    } finally {
      await iterator.cancel();
    }
  });
}

Map<String, dynamic> _statMap({
  required String leagueId,
  required String userId,
}) {
  return {
    GNEsportLeagueStat.fieldUserId: userId,
    GNEsportLeagueStat.fieldLeagueId: leagueId,
    GNEsportLeagueStat.fieldMatchesPlayed: 0,
    GNEsportLeagueStat.fieldGoals: 0,
    GNEsportLeagueStat.fieldGoalsConceded: 0,
    GNEsportLeagueStat.fieldWins: 0,
    GNEsportLeagueStat.fieldDraws: 0,
    GNEsportLeagueStat.fieldLosses: 0,
  };
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
