import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/failure.dart';
import 'package:pes_arena/data/sync/mapping_target.dart';
import 'package:pes_arena/data/sync/migration_plan.dart';
import 'package:pes_arena/data/sync/offline_to_online_migrator.dart';
import 'package:pes_arena/data/sync/sync_remote_gateway.dart';
import 'package:pes_arena/offline/domain/entities/league_model.dart';
import 'package:pes_arena/offline/domain/repositories/league_repository.dart';
import 'package:pes_arena/presentation/sync/bloc/sync_bloc.dart';

import '../../../_helpers/sync_fixtures.dart';

class _MockOfflineRepo extends Mock implements LeagueRepository {}

class _MockGateway extends Mock implements SyncRemoteGateway {}

class _MockMigrator extends Mock implements OfflineToOnlineMigrator {}

class _LeagueModelFake extends Fake implements LeagueModel {}

class _PlanFake extends Fake implements MigrationPlan {}

MigrationPlan _samplePlan({String leagueId = 'L1', int ops = 5}) {
  return MigrationPlan(
    placeholderUsers: const [],
    groupId: 'G1',
    uidsToAddToGroup: const ['uidA'],
    leagueId: leagueId,
    leagueData: const {'name': 'X'},
    participantUids: const ['uidA'],
    statDocs: List.generate(
      ops - 2,
      (i) => PlannedStatDoc(
        id: 's$i',
        userId: 'uidA',
        matchesPlayed: 0,
        goals: 0,
        goalsConceded: 0,
        wins: 0,
        draws: 0,
        losses: 0,
      ),
    ),
    matches: const [],
  );
}

void main() {
  late _MockOfflineRepo repo;
  late _MockGateway gateway;
  late _MockMigrator migrator;

  setUpAll(() {
    registerFallbackValue(const GetLeagueParams(0));
    registerFallbackValue(GetLeaguesParams());
    registerFallbackValue(_LeagueModelFake());
    registerFallbackValue(_PlanFake());
    registerFallbackValue(<int, MappingTarget>{});
  });

  setUp(() {
    repo = _MockOfflineRepo();
    gateway = _MockGateway();
    migrator = _MockMigrator();
  });

  SyncBloc build({String? uid = 'me'}) => SyncBloc(
        offlineLeagueRepository: repo,
        gateway: gateway,
        migrator: migrator,
        currentUid: () => uid,
      );

  group('SyncLoadInitialData', () {
    blocTest<SyncBloc, SyncState>(
      'loads offline leagues + my groups',
      build: () {
        final p = offlinePlayer(1, 'A');
        final league = offlineLeagueFixture(
          players: [p],
          roundsMatches: const [],
        );
        when(() => repo.getLeagues(any()))
            .thenAnswer((_) async => Right([league]));
        when(() => gateway.getMyGroups())
            .thenAnswer((_) async => [onlineGroup('G1')]);
        return build();
      },
      act: (b) => b.add(const SyncLoadInitialData()),
      expect: () => [
        isA<SyncState>().having((s) => s.status, 'status', SyncStatus.loading),
        isA<SyncState>()
            .having((s) => s.status, 'status', SyncStatus.ready)
            .having((s) => s.offlineLeagues, 'leagues', hasLength(1))
            .having((s) => s.myGroups, 'groups', hasLength(1)),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'emits error when gateway throws',
      build: () {
        when(() => repo.getLeagues(any()))
            .thenAnswer((_) async => const Right([]));
        when(() => gateway.getMyGroups()).thenThrow(StateError('boom'));
        return build();
      },
      act: (b) => b.add(const SyncLoadInitialData()),
      expect: () => [
        isA<SyncState>().having((s) => s.status, 'status', SyncStatus.loading),
        isA<SyncState>().having((s) => s.status, 'status', SyncStatus.error),
      ],
    );
  });

  group('SyncSelectGroup', () {
    blocTest<SyncBloc, SyncState>(
      'changing group resets mappings',
      build: () {
        when(() => gateway.getGroupMembers(any()))
            .thenAnswer((_) async => const []);
        return build();
      },
      seed: () => SyncState(
        myGroups: [onlineGroup('G1'), onlineGroup('G2')],
        selectedGroup: onlineGroup('G1'),
        mappings: const {1: MapToExisting('staleUid')},
      ),
      act: (b) => b.add(const SyncSelectGroup('G2')),
      expect: () => [
        isA<SyncState>()
            .having((s) => s.selectedGroup?.id, 'group', 'G2')
            .having((s) => s.mappings, 'mappings', isEmpty),
        isA<SyncState>().having((s) => s.status, 'status', SyncStatus.ready),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'reselect same group keeps mappings',
      build: () {
        when(() => gateway.getGroupMembers(any()))
            .thenAnswer((_) async => const []);
        return build();
      },
      seed: () => SyncState(
        myGroups: [onlineGroup('G1')],
        selectedGroup: onlineGroup('G1'),
        mappings: const {1: MapToExisting('uidA')},
      ),
      act: (b) => b.add(const SyncSelectGroup('G1')),
      expect: () => [
        isA<SyncState>().having((s) => s.mappings, 'kept',
            {1: const MapToExisting('uidA')}),
        isA<SyncState>().having((s) => s.status, 'status', SyncStatus.ready),
      ],
    );
  });

  group('SyncGoToStep preview — buildPlan', () {
    blocTest<SyncBloc, SyncState>(
      'builds plan + transitions to preview',
      build: () {
        when(() => migrator.buildPlan(
              offlineLeague: any(named: 'offlineLeague'),
              groupId: any(named: 'groupId'),
              currentUserUid: any(named: 'currentUserUid'),
              mappings: any(named: 'mappings'),
            )).thenReturn(_samplePlan());
        return build();
      },
      seed: () {
        final p1 = offlinePlayer(1, 'A');
        return SyncState(
          selectedLeague:
              offlineLeagueFixture(players: [p1], roundsMatches: const []),
          selectedGroup: onlineGroup('G1'),
          mappings: const {1: MapToExisting('uidA')},
        );
      },
      act: (b) => b.add(const SyncGoToStep(SyncStep.preview)),
      expect: () => [
        isA<SyncState>()
            .having((s) => s.step, 'step', SyncStep.preview)
            .having((s) => s.plan, 'plan', isNotNull),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'PlanTooLargeException → stay on mapPlayers + show error',
      build: () {
        when(() => migrator.buildPlan(
              offlineLeague: any(named: 'offlineLeague'),
              groupId: any(named: 'groupId'),
              currentUserUid: any(named: 'currentUserUid'),
              mappings: any(named: 'mappings'),
            )).thenThrow(PlanTooLargeException(700));
        return build();
      },
      seed: () {
        final p1 = offlinePlayer(1, 'A');
        return SyncState(
          step: SyncStep.mapPlayers,
          selectedLeague:
              offlineLeagueFixture(players: [p1], roundsMatches: const []),
          selectedGroup: onlineGroup('G1'),
          mappings: const {1: MapToExisting('uidA')},
        );
      },
      act: (b) => b.add(const SyncGoToStep(SyncStep.preview)),
      expect: () => [
        isA<SyncState>()
            .having((s) => s.step, 'step', SyncStep.mapPlayers)
            .having((s) => s.status, 'status', SyncStatus.error)
            .having((s) => s.errorMessage, 'msg', contains('700')),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'errors when current uid is null',
      build: () => build(uid: null),
      seed: () {
        final p1 = offlinePlayer(1, 'A');
        return SyncState(
          selectedLeague:
              offlineLeagueFixture(players: [p1], roundsMatches: const []),
          selectedGroup: onlineGroup('G1'),
          mappings: const {1: MapToExisting('uidA')},
        );
      },
      act: (b) => b.add(const SyncGoToStep(SyncStep.preview)),
      expect: () => [
        isA<SyncState>()
            .having((s) => s.status, 'status', SyncStatus.error),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'going to non-preview step does not call buildPlan',
      build: () => build(),
      act: (b) => b.add(const SyncGoToStep(SyncStep.mapPlayers)),
      expect: () => [
        isA<SyncState>().having((s) => s.step, 'step', SyncStep.mapPlayers),
      ],
      verify: (_) => verifyNever(() => migrator.buildPlan(
            offlineLeague: any(named: 'offlineLeague'),
            groupId: any(named: 'groupId'),
            currentUserUid: any(named: 'currentUserUid'),
            mappings: any(named: 'mappings'),
          )),
    );
  });

  group('mapping events invalidate plan', () {
    blocTest<SyncBloc, SyncState>(
      'SyncSetMapping clears stale plan',
      build: () => build(),
      seed: () => SyncState(plan: _samplePlan()),
      act: (b) => b.add(const SyncSetMapping(
        playerId: 1,
        target: MapToExisting('uidA'),
      )),
      expect: () => [
        isA<SyncState>()
            .having((s) => s.mappings, 'mapping', hasLength(1))
            .having((s) => s.plan, 'plan cleared', isNull),
      ],
    );
  });

  group('SyncRun', () {
    LeagueModel league() {
      final p1 = offlinePlayer(1, 'A');
      return offlineLeagueFixture(
        id: 9,
        players: [p1],
        roundsMatches: const [],
      );
    }

    blocTest<SyncBloc, SyncState>(
      'errors when plan is missing',
      build: () => build(),
      seed: () => SyncState(selectedLeague: league()),
      act: (b) => b.add(const SyncRun()),
      expect: () => [
        isA<SyncState>().having((s) => s.status, 'status', SyncStatus.error),
      ],
    );

    blocTest<SyncBloc, SyncState>(
      'happy path: commit + delete offline + success',
      build: () {
        when(() => migrator.commit(any())).thenAnswer((_) async {});
        when(() => repo.deleteLeauge(any()))
            .thenAnswer((_) async => const Right(1));
        return build();
      },
      seed: () => SyncState(
        selectedLeague: league(),
        plan: _samplePlan(leagueId: 'newL'),
      ),
      act: (b) => b.add(const SyncRun()),
      expect: () => [
        isA<SyncState>()
            .having((s) => s.status, 'status', SyncStatus.running)
            .having((s) => s.step, 'step', SyncStep.executing)
            .having((s) => s.progressLabel, 'label', contains('bản ghi')),
        isA<SyncState>()
            .having((s) => s.status, 'status', SyncStatus.success)
            .having((s) => s.createdLeagueId, 'leagueId', 'newL'),
      ],
      verify: (_) {
        verify(() => migrator.commit(any())).called(1);
        verify(() => repo.deleteLeauge(const GetLeagueParams(9))).called(1);
      },
    );

    blocTest<SyncBloc, SyncState>(
      'commit fail → error + offline league NOT deleted',
      build: () {
        when(() => migrator.commit(any())).thenThrow(StateError('quota'));
        return build();
      },
      seed: () => SyncState(
        selectedLeague: league(),
        plan: _samplePlan(),
      ),
      act: (b) => b.add(const SyncRun()),
      expect: () => [
        isA<SyncState>().having((s) => s.status, 'status', SyncStatus.running),
        isA<SyncState>()
            .having((s) => s.status, 'status', SyncStatus.error)
            .having((s) => s.errorMessage, 'msg',
                contains('Không có dữ liệu nào được tạo')),
      ],
      verify: (_) => verifyNever(() => repo.deleteLeauge(any())),
    );

    blocTest<SyncBloc, SyncState>(
      'offline read failure on SelectLeague propagates',
      build: () {
        when(() => repo.getLeague(any()))
            .thenAnswer((_) async => const Left(LocalFailure('disk')));
        return build();
      },
      act: (b) => b.add(const SyncSelectOfflineLeague(7)),
      expect: () => [
        isA<SyncState>().having((s) => s.status, 'status', SyncStatus.loading),
        isA<SyncState>().having((s) => s.status, 'status', SyncStatus.error),
      ],
    );
  });

  group('SyncState.canGoToPreview', () {
    test('false when no selected league', () {
      expect(const SyncState().canGoToPreview, isFalse);
    });

    test('false when missing mapping', () {
      final p1 = offlinePlayer(1, 'A');
      final p2 = offlinePlayer(2, 'B');
      final state = SyncState(
        selectedLeague:
            offlineLeagueFixture(players: [p1, p2], roundsMatches: const []),
        mappings: const {1: MapToExisting('uidA')},
      );
      expect(state.canGoToPreview, isFalse);
    });

    test('false on duplicate uid', () {
      final p1 = offlinePlayer(1, 'A');
      final p2 = offlinePlayer(2, 'B');
      final state = SyncState(
        selectedLeague:
            offlineLeagueFixture(players: [p1, p2], roundsMatches: const []),
        mappings: const {
          1: MapToExisting('same'),
          2: MapToExisting('same'),
        },
      );
      expect(state.canGoToPreview, isFalse);
    });

    test('true when all mapped + unique uids', () {
      final p1 = offlinePlayer(1, 'A');
      final p2 = offlinePlayer(2, 'B');
      final state = SyncState(
        selectedLeague:
            offlineLeagueFixture(players: [p1, p2], roundsMatches: const []),
        mappings: const {
          1: MapToExisting('a'),
          2: CreatePlaceholder('B'),
        },
      );
      expect(state.canGoToPreview, isTrue);
    });
  });
}
