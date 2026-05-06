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
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/models/group_overview.dart';
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

GNEsportLeague _league(String id, {int year = 2026, String? status}) =>
    GNEsportLeague(
      id: id,
      ownerId: 'owner1',
      groupId: 'G1',
      name: 'League $id',
      startDate: DateTime(year, 1, 1),
      isActive: status != 'finished',
      description: '',
      participants: const [],
      status: status,
    );

GNEsportLeagueStat _leagueStat(String leagueId, String userId,
        {int wins = 1}) =>
    GNEsportLeagueStat(
      id: '$leagueId-$userId',
      leagueId: leagueId,
      userId: userId,
      matchesPlayed: 3,
      wins: wins,
      draws: 0,
      losses: 3 - wins,
      goals: wins * 2,
      goalsConceded: (3 - wins) * 2,
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

  group('AddPlaceholderMember', () {
    GNUser placeholderUser() => GNUser(
          id: 'placeholder_abc',
          displayName: 'Tân thủ',
          email: null,
          phoneNumber: null,
          photoUrl: null,
          role: 'user',
          fcmToken: '',
          isPlaceholder: true,
        );

    GroupDetailBloc blocWithPlaceholder({
      required Future<GNUser> Function({required String displayName})
          createPlaceholderUser,
    }) =>
        GroupDetailBloc(
          groupRepo,
          leagueRepo,
          statsRepo,
          cache,
          _FakeFirestore(),
          _group(),
          currentUserId: 'owner1',
          recomputeTimeout: const Duration(seconds: 2),
          createPlaceholderUser: createPlaceholderUser,
        );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'success: tạo placeholder rồi thêm vào nhóm, emit loading đầu tiên, gọi addMember',
      build: () => blocWithPlaceholder(
        createPlaceholderUser: ({required displayName}) async =>
            placeholderUser(),
      ),
      setUp: () {
        when(() => groupRepo.addMemberToGroup(
              groupId: 'G1',
              memberId: 'placeholder_abc',
            )).thenAnswer((_) async {});
        when(() => groupRepo.getMembersOfGroup('G1'))
            .thenAnswer((_) async => []);
        when(() => groupRepo.getGroup('G1')).thenAnswer((_) async => _group());
      },
      act: (b) => b.add(const AddPlaceholderMember('G1', 'Tân thủ')),
      // GetMembers/GetGroupDetail cascading: Equatable dedup makes exact count
      // non-deterministic. Assert on semantics only.
      expect: () => isA<List<GroupDetailState>>()
          .having((l) => l.isNotEmpty, 'isNotEmpty', isTrue)
          .having(
            (l) => l.first.viewStatus,
            'first state is loading',
            ViewStatus.loading,
          )
          .having(
            (l) => l.any((s) => s.viewStatus == ViewStatus.failure),
            'no failure emitted',
            isFalse,
          ),
      verify: (_) {
        verify(() => groupRepo.addMemberToGroup(
              groupId: 'G1',
              memberId: 'placeholder_abc',
            )).called(1);
      },
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'failure khi createPlaceholderUser ném lỗi → emit failure',
      build: () => blocWithPlaceholder(
        createPlaceholderUser: ({required displayName}) async =>
            throw Exception('firestore error'),
      ),
      act: (b) => b.add(const AddPlaceholderMember('G1', 'Tân thủ')),
      expect: () => [
        isA<GroupDetailState>()
            .having((s) => s.viewStatus, 'viewStatus', ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.viewStatus, 'viewStatus', ViewStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                contains('firestore error')),
      ],
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'failure khi addMemberToGroup ném lỗi → emit failure',
      build: () => blocWithPlaceholder(
        createPlaceholderUser: ({required displayName}) async =>
            placeholderUser(),
      ),
      setUp: () {
        when(() => groupRepo.addMemberToGroup(
              groupId: any(named: 'groupId'),
              memberId: any(named: 'memberId'),
            )).thenThrow(Exception('network error'));
      },
      act: (b) => b.add(const AddPlaceholderMember('G1', 'Tân thủ')),
      expect: () => [
        isA<GroupDetailState>()
            .having((s) => s.viewStatus, 'viewStatus', ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.viewStatus, 'viewStatus', ViewStatus.failure)
            .having((s) => s.errorMessage, 'errorMessage',
                contains('network error')),
      ],
    );
  });

  group('AddPlaceholderMember props', () {
    test('AddPlaceholderMember equatable props', () {
      const e1 = AddPlaceholderMember('G1', 'Tân thủ');
      const e2 = AddPlaceholderMember('G1', 'Tân thủ');
      const e3 = AddPlaceholderMember('G1', 'Khác');
      expect(e1, equals(e2));
      expect(e1, isNot(equals(e3)));
    });
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

  group('FilterGroupOverviewByYear', () {
    final league2025 = _league('L1', year: 2025, status: 'finished');
    final league2024 = _league('L2', year: 2024, status: 'finished');

    GroupDetailState seedWithLeagues() => GroupDetailState(
          group: _group(),
          leagues: [league2025, league2024],
          leaguesStatus: ViewStatus.success,
        );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'year == null → reset selectedOverviewYear, giữ cache',
      build: bloc,
      seed: () => GroupDetailState(
        group: _group(),
        leagues: [league2025],
        leaguesStatus: ViewStatus.success,
        selectedOverviewYear: 2025,
        yearlyOverviews: {2025: const GroupOverview.empty()},
      ),
      act: (b) => b.add(const FilterGroupOverviewByYear(null)),
      expect: () => [
        isA<GroupDetailState>()
            .having((s) => s.selectedOverviewYear, 'selectedYear', isNull)
            .having(
                (s) => s.yearlyOverviews.containsKey(2025), 'cache kept', true),
      ],
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'cache hit → chỉ emit selectedOverviewYear, không gọi getLeagueStats',
      build: bloc,
      seed: () => GroupDetailState(
        group: _group(),
        leagues: [league2025],
        leaguesStatus: ViewStatus.success,
        yearlyOverviews: {2025: const GroupOverview.empty()},
      ),
      act: (b) => b.add(const FilterGroupOverviewByYear(2025)),
      expect: () => [
        isA<GroupDetailState>()
            .having((s) => s.selectedOverviewYear, 'selectedYear', 2025)
            .having((s) => s.filteredOverviewStatus, 'filteredStatus',
                ViewStatus.initial),
      ],
      verify: (_) =>
          verifyNever(() => leagueRepo.getLeagueStats(any())),
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'cache miss → loading rồi success, lưu vào yearlyOverviews',
      build: bloc,
      seed: seedWithLeagues,
      setUp: () {
        when(() => leagueRepo.getLeagueStats('L1')).thenAnswer(
          (_) async => [_leagueStat('L1', 'A', wins: 2)],
        );
      },
      act: (b) => b.add(const FilterGroupOverviewByYear(2025)),
      expect: () => [
        isA<GroupDetailState>()
            .having((s) => s.selectedOverviewYear, 'selectedYear', 2025)
            .having((s) => s.filteredOverviewStatus, 'status',
                ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.filteredOverviewStatus, 'status',
                ViewStatus.success)
            .having((s) => s.yearlyOverviews.containsKey(2025), 'cached', true),
      ],
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'cache miss → chỉ fetch leagues trong năm được chọn',
      build: bloc,
      seed: seedWithLeagues,
      setUp: () {
        when(() => leagueRepo.getLeagueStats('L1')).thenAnswer(
          (_) async => [_leagueStat('L1', 'A')],
        );
      },
      act: (b) => b.add(const FilterGroupOverviewByYear(2025)),
      verify: (_) {
        verify(() => leagueRepo.getLeagueStats('L1')).called(1);
        verifyNever(() => leagueRepo.getLeagueStats('L2'));
      },
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'lần gọi thứ 2 với cùng năm dùng cache, không fetch lại',
      build: bloc,
      seed: seedWithLeagues,
      setUp: () {
        when(() => leagueRepo.getLeagueStats('L1')).thenAnswer(
          (_) async => [_leagueStat('L1', 'A')],
        );
      },
      act: (b) async {
        b.add(const FilterGroupOverviewByYear(2025));
        await Future.delayed(const Duration(milliseconds: 50));
        b.add(const FilterGroupOverviewByYear(2025));
      },
      verify: (_) =>
          verify(() => leagueRepo.getLeagueStats('L1')).called(1),
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'năm không có league → yearlyOverviews lưu empty overview',
      build: bloc,
      seed: seedWithLeagues,
      act: (b) => b.add(const FilterGroupOverviewByYear(2023)),
      expect: () => [
        isA<GroupDetailState>()
            .having((s) => s.filteredOverviewStatus, 'status',
                ViewStatus.loading),
        isA<GroupDetailState>()
            .having((s) => s.filteredOverviewStatus, 'status',
                ViewStatus.success)
            .having(
              (s) => s.yearlyOverviews[2023]?.totalLeagues,
              'totalLeagues',
              0,
            ),
      ],
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'repo ném lỗi → filteredOverviewStatus = failure',
      build: bloc,
      seed: seedWithLeagues,
      setUp: () {
        when(() => leagueRepo.getLeagueStats('L1'))
            .thenThrow(Exception('network'));
      },
      act: (b) => b.add(const FilterGroupOverviewByYear(2025)),
      expect: () => [
        isA<GroupDetailState>()
            .having((s) => s.filteredOverviewStatus, 'status',
                ViewStatus.loading),
        isA<GroupDetailState>().having(
            (s) => s.filteredOverviewStatus, 'status', ViewStatus.failure),
      ],
    );

    blocTest<GroupDetailBloc, GroupDetailState>(
      'activeOverview trả overview all-time khi selectedYear == null',
      build: bloc,
      seed: () => GroupDetailState(
        group: _group(),
        overview: const GroupOverview(
          totalLeagues: 10,
          finishedLeagues: 8,
          totalMatchesPlayed: 40,
          totalGoals: 120,
          champion: null,
          runnerUpKing: null,
          drawKing: null,
          ironDefense: null,
          master: null,
          playerStats: [],
        ),
      ),
      act: (b) => b.add(const FilterGroupOverviewByYear(null)),
      verify: (b) {
        expect(b.state.activeOverview?.totalLeagues, 10);
      },
    );
  });
}
