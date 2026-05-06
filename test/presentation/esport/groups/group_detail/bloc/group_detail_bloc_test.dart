import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart'; // ignore: unused_import
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/cache/group_overview_cache.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_repository.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_stats_repository.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/group/stats/gn_esport_group_stats_summary.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockGroupRepo extends Mock implements EsportGroupRepository {}

class _MockLeagueRepo extends Mock implements EsportLeagueRepository {}

class _MockStatsRepo extends Mock implements EsportGroupStatsRepository {}

class _FakeFirestore extends Fake implements GNFirestore {
  @override
  Future<Map<String, GNUser>> getUsersById(List<String> userIds) async =>
      <String, GNUser>{};
}

GNEsportGroup _group({String ownerId = 'owner1'}) => GNEsportGroup(
      id: 'G1',
      groupName: 'Test Group',
      ownerId: ownerId,
      members: const ['owner1'],
      description: '',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      status: 'active',
    );

GNEsportLeague _league(String id) => GNEsportLeague(
      id: id,
      ownerId: 'owner1',
      groupId: 'G1',
      name: 'League $id',
      startDate: DateTime(2026, 1, 1),
      isActive: true,
      description: '',
      participants: const [],
    );

GNEsportGroupStatsSummary _summary({
  int totalLeagues = 1,
  int finishedLeagues = 1,
  List<GNEsportGroupPlayerEntry> players = const [],
}) =>
    GNEsportGroupStatsSummary(
      groupId: 'G1',
      totalLeagues: totalLeagues,
      finishedLeagues: finishedLeagues,
      playerStats: players,
      updatedAt: null,
      schemaVersion: GNEsportGroupStatsSummary.kCurrentSchemaVersion,
    );

void main() {
  late _MockGroupRepo groupRepo;
  late _MockLeagueRepo leagueRepo;
  late _MockStatsRepo statsRepo;
  late GroupOverviewCache cache;

  setUp(() async {
    groupRepo = _MockGroupRepo();
    leagueRepo = _MockLeagueRepo();
    statsRepo = _MockStatsRepo();
    SharedPreferences.setMockInitialValues({});
    cache = GroupOverviewCache(await SharedPreferences.getInstance());
    setShowToastImpl((msg, {gravity = ToastGravity.BOTTOM}) {});
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  GroupDetailBloc bloc() => GroupDetailBloc(
        groupRepo,
        leagueRepo,
        statsRepo,
        cache,
        _FakeFirestore(),
        _group(),
        currentUserId: 'owner1',
        recomputeTimeout: const Duration(seconds: 2),
      );

  group('LoadGroupLeagues', () {
    blocTest<GroupDetailBloc, GroupDetailState>(
      'phát ra leaguesStatus loading → success khi load thành công',
      build: bloc,
      setUp: () {
        when(() => leagueRepo.getLeaguesByGroupId('G1'))
            .thenAnswer((_) async => [_league('L1'), _league('L2')]);
      },
      act: (b) => b.add(const LoadGroupLeagues('G1')),
      expect: () => [
        isA<GroupDetailState>()
            .having((s) => s.leaguesStatus, 'leaguesStatus', ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.leaguesStatus, 'leaguesStatus', ViewStatus.success)
            .having((s) => s.leagues.length, 'leagues.length', 2),
      ],
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'phát ra leaguesStatus failure khi repo ném lỗi',
      build: bloc,
      setUp: () {
        when(() => leagueRepo.getLeaguesByGroupId('G1'))
            .thenThrow(Exception('network error'));
      },
      act: (b) => b.add(const LoadGroupLeagues('G1')),
      expect: () => [
        isA<GroupDetailState>()
            .having((s) => s.leaguesStatus, 'leaguesStatus', ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.leaguesStatus, 'leaguesStatus', ViewStatus.failure),
      ],
    );
  });

  group('SetLeagueMergeCompleted', () {
    blocTest<GroupDetailBloc, GroupDetailState>(
      'cập nhật mergeCompleted = true trong local state',
      build: bloc,
      seed: () => GroupDetailState(group: _group(), leagues: [_league('L1')]),
      setUp: () {
        when(() => leagueRepo.setMergeCompleted('L1', completed: true))
            .thenAnswer((_) async {});
      },
      act: (b) => b.add(const SetLeagueMergeCompleted(
        leagueId: 'L1',
        completed: true,
      )),
      expect: () => [
        isA<GroupDetailState>().having(
          (s) => s.leagues.first.mergeCompleted,
          'mergeCompleted',
          true,
        ),
      ],
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'toggle mergeCompleted = false',
      build: bloc,
      seed: () => GroupDetailState(
        group: _group(),
        leagues: [_league('L1').copyWith(mergeCompleted: true)],
      ),
      setUp: () {
        when(() => leagueRepo.setMergeCompleted('L1', completed: false))
            .thenAnswer((_) async {});
      },
      act: (b) => b.add(const SetLeagueMergeCompleted(
        leagueId: 'L1',
        completed: false,
      )),
      expect: () => [
        isA<GroupDetailState>().having(
          (s) => s.leagues.first.mergeCompleted,
          'mergeCompleted',
          false,
        ),
      ],
    );
  });

  group('LoadGroupOverview', () {
    blocTest<GroupDetailBloc, GroupDetailState>(
      'success path: đọc summary doc → emit overview',
      build: bloc,
      setUp: () {
        when(() => statsRepo.getSummary('G1'))
            .thenAnswer((_) async => _summary(totalLeagues: 3));
      },
      act: (b) => b.add(const LoadGroupOverview('G1')),
      expect: () => [
        isA<GroupDetailState>().having(
            (s) => s.overviewStatus, 'overviewStatus', ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.overviewStatus, 'overviewStatus',
                ViewStatus.success)
            .having((s) => s.overview?.totalLeagues, 'totalLeagues', 3)
            .having((s) => s.overviewIsStale, 'isStale', isFalse),
      ],
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'lazy backfill: summary null → request recompute và chờ stream emit',
      build: bloc,
      setUp: () {
        when(() => statsRepo.getSummary('G1'))
            .thenAnswer((_) async => null);
        when(() => statsRepo.requestRecompute('G1'))
            .thenAnswer((_) async {});
        when(() => statsRepo.listenSummary('G1')).thenAnswer((_) =>
            Stream.value(_summary(totalLeagues: 5)));
      },
      act: (b) => b.add(const LoadGroupOverview('G1')),
      expect: () => [
        isA<GroupDetailState>().having(
            (s) => s.overviewStatus, 'overviewStatus', ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.overviewStatus, 'overviewStatus',
                ViewStatus.success)
            .having((s) => s.overview?.totalLeagues, 'totalLeagues', 5),
      ],
      verify: (_) {
        verify(() => statsRepo.requestRecompute('G1')).called(1);
      },
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'forceRefresh: skip first emission, lấy doc thứ 2 sau recompute',
      build: bloc,
      setUp: () {
        when(() => statsRepo.requestRecompute('G1'))
            .thenAnswer((_) async {});
        // First emit = stale; second emit = freshly computed
        when(() => statsRepo.listenSummary('G1')).thenAnswer((_) =>
            Stream.fromIterable([
              _summary(totalLeagues: 1),
              _summary(totalLeagues: 9),
            ]));
      },
      act: (b) => b.add(const LoadGroupOverview('G1', forceRefresh: true)),
      expect: () => [
        isA<GroupDetailState>().having(
            (s) => s.overviewStatus, 'overviewStatus', ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.overviewStatus, 'overviewStatus',
                ViewStatus.success)
            .having((s) => s.overview?.totalLeagues, 'totalLeagues', 9),
      ],
      verify: (_) {
        verify(() => statsRepo.requestRecompute('G1')).called(1);
        verifyNever(() => statsRepo.getSummary('G1'));
      },
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'failure path khi không có overview cũ → emit failure',
      build: bloc,
      setUp: () {
        when(() => statsRepo.getSummary('G1'))
            .thenThrow(Exception('boom'));
      },
      act: (b) => b.add(const LoadGroupOverview('G1')),
      expect: () => [
        isA<GroupDetailState>().having(
            (s) => s.overviewStatus, 'overviewStatus', ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.overviewStatus, 'overviewStatus',
                ViewStatus.failure)
            .having((s) => s.overviewErrorMessage, 'errorMessage',
                contains('boom')),
      ],
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'transient error: giữ overview cũ và mark stale',
      build: bloc,
      seed: () {
        // Pre-populate cache so first paint shows cached, then fetch fails.
        cache.write('G1', _summary(totalLeagues: 7));
        return GroupDetailState(group: _group());
      },
      setUp: () {
        when(() => statsRepo.getSummary('G1'))
            .thenThrow(Exception('network down'));
      },
      act: (b) => b.add(const LoadGroupOverview('G1')),
      expect: () => [
        // Cache hydration first
        isA<GroupDetailState>()
            .having((s) => s.overviewStatus, 'overviewStatus',
                ViewStatus.success)
            .having((s) => s.overviewIsStale, 'isStale', isTrue),
        // Then network fails — keep prior overview, still success but stale
        isA<GroupDetailState>()
            .having((s) => s.overviewStatus, 'overviewStatus',
                ViewStatus.success)
            .having((s) => s.overviewIsStale, 'isStale', isTrue)
            .having((s) => s.overviewErrorMessage, 'err',
                contains('network down')),
      ],
    );
  });

  group('ReplaceLeagueParticipant', () {
    blocTest<GroupDetailBloc, GroupDetailState>(
      'phát ra replaceParticipantStatus loading → success và tự load lại leagues',
      build: bloc,
      setUp: () {
        when(() => leagueRepo.replaceParticipant(
              leagueId: 'L1',
              oldUserId: 'old',
              newUserId: 'new',
            )).thenAnswer((_) async {});
        when(() => leagueRepo.getLeaguesByGroupId('G1'))
            .thenAnswer((_) async => [_league('L1')]);
      },
      act: (b) => b.add(const ReplaceLeagueParticipant(
        leagueId: 'L1',
        oldUserId: 'old',
        newUserId: 'new',
      )),
      expect: () => [
        isA<GroupDetailState>().having(
            (s) => s.replaceParticipantStatus,
            'status',
            ViewStatus.loading),
        isA<GroupDetailState>().having(
            (s) => s.replaceParticipantStatus,
            'status',
            ViewStatus.success),
        isA<GroupDetailState>()
            .having((s) => s.leaguesStatus, 'leaguesStatus', ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.leaguesStatus, 'leaguesStatus', ViewStatus.success),
      ],
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'phát ra replaceParticipantStatus failure khi repo ném lỗi',
      build: bloc,
      setUp: () {
        when(() => leagueRepo.replaceParticipant(
              leagueId: 'L1',
              oldUserId: 'old',
              newUserId: 'new',
            )).thenThrow(Exception('replace failed'));
      },
      act: (b) => b.add(const ReplaceLeagueParticipant(
        leagueId: 'L1',
        oldUserId: 'old',
        newUserId: 'new',
      )),
      expect: () => [
        isA<GroupDetailState>().having(
            (s) => s.replaceParticipantStatus,
            'status',
            ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.replaceParticipantStatus, 'status',
                ViewStatus.failure)
            .having((s) => s.replaceErrorMessage, 'replaceErrorMessage',
                contains('replace failed')),
      ],
    );
  });
}
