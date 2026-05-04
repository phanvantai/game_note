import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/data/sync/mapping_target.dart';
import 'package:pes_arena/data/sync/migration_plan.dart';
import 'package:pes_arena/data/sync/offline_to_online_migrator.dart';
import 'package:pes_arena/data/sync/sync_remote_gateway.dart';

import '../../_helpers/sync_fixtures.dart';

class _MockGateway extends Mock implements SyncRemoteGateway {}

class _PlanFake extends Fake implements MigrationPlan {}

void main() {
  late _MockGateway gateway;
  late OfflineToOnlineMigrator migrator;

  setUpAll(() => registerFallbackValue(_PlanFake()));

  setUp(() {
    gateway = _MockGateway();
    var counter = 0;
    migrator = OfflineToOnlineMigrator(
      gateway,
      idGenerator: () => 'id${++counter}',
    );
  });

  group('buildPlan — happy path', () {
    test('places placeholder users + maps existing uids correctly', () {
      final p1 = offlinePlayer(1, 'A');
      final p2 = offlinePlayer(2, 'B');
      final league = offlineLeagueFixture(
        players: [p1, p2],
        roundsMatches: [
          [
            offlineMatch(
              matchId: 10,
              roundId: 1,
              home: p1,
              away: p2,
              homeScore: 3,
              awayScore: 1,
            ),
          ],
        ],
      );
      final plan = migrator.buildPlan(
        offlineLeague: league,
        groupId: 'G',
        currentUserUid: 'currentUid',
        mappings: {
          1: const MapToExisting('uidA'),
          2: const CreatePlaceholder('B'),
        },
      );

      // 1 placeholder + 1 group update + 1 league + 2 stats + 1 match = 6 ops.
      expect(plan.totalOps, 6);
      expect(plan.placeholderUsers, hasLength(1));
      expect(plan.placeholderUsers.first.id, startsWith('placeholder_'));
      expect(plan.placeholderUsers.first.displayName, 'B');

      // Both uids should be in addToGroup + participants.
      final placeholderId = plan.placeholderUsers.first.id;
      expect(plan.uidsToAddToGroup, containsAll(['uidA', placeholderId]));
      expect(plan.participantUids, containsAll(['uidA', placeholderId]));

      // Match references resolved uids.
      expect(plan.matches.first.homeTeamId, 'uidA');
      expect(plan.matches.first.awayTeamId, placeholderId);
      expect(plan.matches.first.homeScore, 3);
      expect(plan.matches.first.awayScore, 1);
    });

    test('computes stats client-side from finished matches', () {
      final p1 = offlinePlayer(1, 'A');
      final p2 = offlinePlayer(2, 'B');
      final league = offlineLeagueFixture(
        players: [p1, p2],
        roundsMatches: [
          [
            offlineMatch(
              matchId: 1,
              roundId: 1,
              home: p1,
              away: p2,
              homeScore: 2,
              awayScore: 0,
            ),
            offlineMatch(
              matchId: 2,
              roundId: 1,
              home: p2,
              away: p1,
              homeScore: 1,
              awayScore: 1,
            ),
          ],
        ],
      );
      final plan = migrator.buildPlan(
        offlineLeague: league,
        groupId: 'G',
        currentUserUid: 'me',
        mappings: {
          1: const MapToExisting('uidA'),
          2: const MapToExisting('uidB'),
        },
      );
      final statA = plan.statDocs.firstWhere((s) => s.userId == 'uidA');
      expect(statA.matchesPlayed, 2);
      expect(statA.wins, 1);
      expect(statA.draws, 1);
      expect(statA.losses, 0);
      expect(statA.goals, 3);
      expect(statA.goalsConceded, 1);

      final statB = plan.statDocs.firstWhere((s) => s.userId == 'uidB');
      expect(statB.wins, 0);
      expect(statB.draws, 1);
      expect(statB.losses, 1);
      expect(statB.goals, 1);
      expect(statB.goalsConceded, 3);
    });

    test('skips unfinished matches', () {
      final p1 = offlinePlayer(1, 'A');
      final p2 = offlinePlayer(2, 'B');
      final league = offlineLeagueFixture(
        players: [p1, p2],
        roundsMatches: [
          [
            offlineMatch(
              matchId: 1,
              roundId: 1,
              home: p1,
              away: p2,
              homeScore: 2,
              awayScore: 0,
            ),
            offlineMatch(
              matchId: 2,
              roundId: 1,
              home: p1,
              away: p2,
              finished: false,
            ),
          ],
        ],
      );
      final plan = migrator.buildPlan(
        offlineLeague: league,
        groupId: 'G',
        currentUserUid: 'me',
        mappings: {
          1: const MapToExisting('uidA'),
          2: const MapToExisting('uidB'),
        },
      );
      expect(plan.matches, hasLength(1));
    });

    test('does not call gateway during plan-building', () {
      final p1 = offlinePlayer(1, 'A');
      final league =
          offlineLeagueFixture(players: [p1], roundsMatches: const []);
      migrator.buildPlan(
        offlineLeague: league,
        groupId: 'G',
        currentUserUid: 'me',
        mappings: {1: const MapToExisting('uidA')},
      );
      verifyZeroInteractions(gateway);
    });
  });

  group('buildPlan — validation', () {
    test('throws on empty mappings', () {
      final league = offlineLeagueFixture(
        players: const [],
        roundsMatches: const [],
      );
      expect(
        () => migrator.buildPlan(
          offlineLeague: league,
          groupId: 'G',
          currentUserUid: 'me',
          mappings: const {},
        ),
        throwsArgumentError,
      );
    });

    test('throws on missing mapping for league player', () {
      final p1 = offlinePlayer(1, 'A');
      final p2 = offlinePlayer(2, 'B');
      final league = offlineLeagueFixture(
        players: [p1, p2],
        roundsMatches: const [],
      );
      expect(
        () => migrator.buildPlan(
          offlineLeague: league,
          groupId: 'G',
          currentUserUid: 'me',
          mappings: {1: const MapToExisting('uidA')},
        ),
        throwsArgumentError,
      );
    });

    test('throws on duplicate uid mapping', () {
      final p1 = offlinePlayer(1, 'A');
      final p2 = offlinePlayer(2, 'B');
      final league = offlineLeagueFixture(
        players: [p1, p2],
        roundsMatches: const [],
      );
      expect(
        () => migrator.buildPlan(
          offlineLeague: league,
          groupId: 'G',
          currentUserUid: 'me',
          mappings: {
            1: const MapToExisting('same'),
            2: const MapToExisting('same'),
          },
        ),
        throwsArgumentError,
      );
    });

    test('throws on unknown offline player id in mapping', () {
      final p1 = offlinePlayer(1, 'A');
      final league =
          offlineLeagueFixture(players: [p1], roundsMatches: const []);
      expect(
        () => migrator.buildPlan(
          offlineLeague: league,
          groupId: 'G',
          currentUserUid: 'me',
          mappings: {
            1: const MapToExisting('uidA'),
            999: const MapToExisting('uidGhost'),
          },
        ),
        throwsArgumentError,
      );
    });
  });

  group('buildPlan — size limit', () {
    test('throws PlanTooLargeException when ops > 500', () {
      // Build a synthetic league with too many matches by reusing 2 players
      // across 500 matches.
      final p1 = offlinePlayer(1, 'A');
      final p2 = offlinePlayer(2, 'B');
      final league = offlineLeagueFixture(
        players: [p1, p2],
        roundsMatches: [
          [
            for (var i = 0; i < 600; i++)
              offlineMatch(
                matchId: i,
                roundId: 1,
                home: p1,
                away: p2,
                homeScore: 1,
                awayScore: 1,
              ),
          ],
        ],
      );
      expect(
        () => migrator.buildPlan(
          offlineLeague: league,
          groupId: 'G',
          currentUserUid: 'me',
          mappings: {
            1: const MapToExisting('uidA'),
            2: const MapToExisting('uidB'),
          },
        ),
        throwsA(isA<PlanTooLargeException>()
            .having((e) => e.totalOps, 'totalOps', greaterThan(500))),
      );
    });
  });

  group('commit', () {
    test('forwards plan to gateway.commitBatch', () async {
      when(() => gateway.commitBatch(any())).thenAnswer((_) async {});
      final p1 = offlinePlayer(1, 'A');
      final league =
          offlineLeagueFixture(players: [p1], roundsMatches: const []);
      final plan = migrator.buildPlan(
        offlineLeague: league,
        groupId: 'G',
        currentUserUid: 'me',
        mappings: {1: const MapToExisting('uidA')},
      );
      await migrator.commit(plan);
      verify(() => gateway.commitBatch(plan)).called(1);
    });

    test('propagates gateway errors as-is', () async {
      when(() => gateway.commitBatch(any())).thenThrow(StateError('quota'));
      final p1 = offlinePlayer(1, 'A');
      final league =
          offlineLeagueFixture(players: [p1], roundsMatches: const []);
      final plan = migrator.buildPlan(
        offlineLeague: league,
        groupId: 'G',
        currentUserUid: 'me',
        mappings: {1: const MapToExisting('uidA')},
      );
      await expectLater(() => migrator.commit(plan), throwsStateError);
    });
  });
}
