import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/cache/dashboard_cache.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/domain/repositories/user_stats_repository.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/firebase/firestore/user/stats/gn_user_stats_summary.dart';
import 'package:pes_arena/presentation/home/dashboard/bloc/dashboard_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/models/dashboard_stats.dart';
import 'package:pes_arena/presentation/home/dashboard/models/recent_match_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockRepo extends Mock implements UserStatsRepository {}

class _MockAuth extends Mock implements GNAuth {}

class _MockUser extends Mock implements User {}

GNUserStatsSummary _summary({
  String userId = 'u1',
  int matchesPlayed = 10,
  int wins = 6,
  int draws = 2,
  int losses = 2,
  int goals = 18,
  int goalsConceded = 9,
  int tournamentsJoined = 3,
  int tournamentsFinished = 2,
  int championCount = 1,
  int runnerUpCount = 1,
  DateTime? lastChampionAt,
  List<GNUserRecentMatch> recentMatches = const [],
  List<GNUserLeaguePerformance> leagueHistory = const [],
}) {
  return GNUserStatsSummary(
    userId: userId,
    matchesPlayed: matchesPlayed,
    wins: wins,
    draws: draws,
    losses: losses,
    goals: goals,
    goalsConceded: goalsConceded,
    tournamentsJoined: tournamentsJoined,
    tournamentsFinished: tournamentsFinished,
    championCount: championCount,
    runnerUpCount: runnerUpCount,
    lastChampionAt: lastChampionAt ?? DateTime(2026, 1, 10),
    recentMatches: recentMatches,
    leagueHistory: leagueHistory,
    updatedAt: DateTime(2026, 5, 1),
    schemaVersion: 1,
  );
}

extension on GNUserStatsSummary {
  GNUserStatsSummary copyWithBasic({
    List<GNUserOpponentStat>? h2hSummary,
  }) {
    return GNUserStatsSummary(
      userId: userId,
      matchesPlayed: matchesPlayed,
      wins: wins,
      draws: draws,
      losses: losses,
      goals: goals,
      goalsConceded: goalsConceded,
      tournamentsJoined: tournamentsJoined,
      tournamentsFinished: tournamentsFinished,
      championCount: championCount,
      runnerUpCount: runnerUpCount,
      lastChampionAt: lastChampionAt,
      recentMatches: recentMatches,
      leagueHistory: leagueHistory,
      h2hSummary: h2hSummary ?? this.h2hSummary,
      updatedAt: updatedAt,
      schemaVersion: schemaVersion,
    );
  }

  GNUserStatsSummary copyWithHistory(List<GNUserLeaguePerformance> h) {
    return GNUserStatsSummary(
      userId: userId,
      matchesPlayed: matchesPlayed,
      wins: wins,
      draws: draws,
      losses: losses,
      goals: goals,
      goalsConceded: goalsConceded,
      tournamentsJoined: tournamentsJoined,
      tournamentsFinished: tournamentsFinished,
      championCount: championCount,
      runnerUpCount: runnerUpCount,
      lastChampionAt: lastChampionAt,
      recentMatches: recentMatches,
      leagueHistory: h,
      updatedAt: updatedAt,
      schemaVersion: schemaVersion,
    );
  }
}

GNUserRecentMatch _recent({
  required String matchId,
  GNRecentMatchResult result = GNRecentMatchResult.win,
  int userScore = 3,
  int opponentScore = 1,
  String opponentId = 'u2',
  DateTime? date,
  DateTime? updatedAt,
}) {
  return GNUserRecentMatch(
    matchId: matchId,
    leagueId: 'l1',
    leagueName: 'Cup',
    date: date ?? DateTime(2026, 4, 1),
    userScore: userScore,
    opponentScore: opponentScore,
    opponentId: opponentId,
    opponentDisplayName: 'Player $opponentId',
    result: result,
    updatedAt: updatedAt,
  );
}

void main() {
  late _MockRepo repo;
  late _MockAuth auth;
  late _MockUser user;
  late DashboardCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    cache = DashboardCache(prefs);
    repo = _MockRepo();
    auth = _MockAuth();
    user = _MockUser();
    when(() => auth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('u1');
  });

  DashboardBloc build() => DashboardBloc(
    userStatsRepository: repo,
    auth: auth,
    cache: cache,
    recomputeTimeout: const Duration(milliseconds: 500),
  );

  blocTest<DashboardBloc, DashboardState>(
    'LoadDashboard map summary doc sang DashboardStats khi không có cache',
    build: () {
      when(() => repo.getSummary('u1')).thenAnswer(
        (_) async => _summary(
          recentMatches: [
            _recent(matchId: 'm1', result: GNRecentMatchResult.win),
            _recent(
              matchId: 'm2',
              result: GNRecentMatchResult.loss,
              userScore: 0,
              opponentScore: 2,
            ),
          ],
        ),
      );
      return build();
    },
    act: (bloc) => bloc.add(LoadDashboard()),
    expect: () => [
      isA<DashboardState>().having(
        (s) => s.viewStatus,
        'status',
        ViewStatus.loading,
      ),
      isA<DashboardState>()
          .having((s) => s.viewStatus, 'status', ViewStatus.success)
          .having((s) => s.isStale, 'stale', false)
          .having((s) => s.stats?.tournamentsJoined, 'joined', 3)
          .having((s) => s.stats?.finishedTournaments, 'finished', 2)
          .having((s) => s.stats?.championCount, 'champion', 1)
          .having((s) => s.stats?.wins, 'wins', 6)
          .having((s) => s.stats?.matchesPlayed, 'matches', 10)
          .having((s) => s.stats?.recentMatches.length, 'recent', 2)
          .having(
            (s) => s.stats?.recentMatches.first.result,
            'first result',
            MatchResult.win,
          ),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'LoadDashboard hydrate cache trước, fetch summary sau (isStale toggles)',
    setUp: () async {
      // Seed cache with prior stats.
      await cache.write(
        'u1',
        const DashboardStats(
          tournamentsJoined: 1,
          finishedTournaments: 0,
          championCount: 0,
          runnerUpCount: 0,
          lastChampionAt: null,
          recentMatches: [],
          wins: 1,
          matchesPlayed: 1,
        ),
      );
    },
    build: () {
      when(() => repo.getSummary('u1')).thenAnswer((_) async => _summary());
      return build();
    },
    act: (bloc) => bloc.add(LoadDashboard()),
    expect: () => [
      isA<DashboardState>()
          .having((s) => s.viewStatus, 'status', ViewStatus.success)
          .having((s) => s.isStale, 'stale', true)
          .having((s) => s.stats?.tournamentsJoined, 'cached', 1),
      isA<DashboardState>()
          .having((s) => s.viewStatus, 'status', ViewStatus.success)
          .having((s) => s.isStale, 'stale', false)
          .having((s) => s.stats?.tournamentsJoined, 'fresh', 3),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'LoadDashboard request recompute và đợi listenSummary khi summary null',
    build: () {
      when(() => repo.getSummary('u1')).thenAnswer((_) async => null);
      when(() => repo.requestRecompute('u1')).thenAnswer((_) async {});
      final controller = StreamController<GNUserStatsSummary?>();
      // Push summary 100ms later — simulating cloud function fan-out.
      Future.delayed(const Duration(milliseconds: 50), () {
        controller.add(null);
        controller.add(_summary());
      });
      when(
        () => repo.listenSummary('u1'),
      ).thenAnswer((_) => controller.stream);
      return build();
    },
    act: (bloc) => bloc.add(LoadDashboard()),
    wait: const Duration(milliseconds: 200),
    expect: () => [
      isA<DashboardState>().having(
        (s) => s.viewStatus,
        'status',
        ViewStatus.loading,
      ),
      isA<DashboardState>()
          .having((s) => s.viewStatus, 'status', ViewStatus.success)
          .having((s) => s.stats?.matchesPlayed, 'matches', 10),
    ],
    verify: (_) {
      verify(() => repo.requestRecompute('u1')).called(1);
    },
  );

  blocTest<DashboardBloc, DashboardState>(
    'LoadDashboard timeout khi recompute không phản hồi → failure (no cache)',
    build: () {
      when(() => repo.getSummary('u1')).thenAnswer((_) async => null);
      when(() => repo.requestRecompute('u1')).thenAnswer((_) async {});
      when(
        () => repo.listenSummary('u1'),
      ).thenAnswer((_) => const Stream<GNUserStatsSummary?>.empty());
      return build();
    },
    act: (bloc) => bloc.add(LoadDashboard()),
    wait: const Duration(milliseconds: 700),
    expect: () => [
      isA<DashboardState>().having(
        (s) => s.viewStatus,
        'status',
        ViewStatus.loading,
      ),
      isA<DashboardState>().having(
        (s) => s.viewStatus,
        'status',
        ViewStatus.failure,
      ),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'LoadDashboard giữ cached stats khi fetch lỗi (chỉ set isStale)',
    setUp: () async {
      await cache.write(
        'u1',
        const DashboardStats(
          tournamentsJoined: 5,
          finishedTournaments: 2,
          championCount: 1,
          runnerUpCount: 0,
          lastChampionAt: null,
          recentMatches: [],
        ),
      );
    },
    build: () {
      when(() => repo.getSummary('u1')).thenThrow(Exception('network'));
      return build();
    },
    act: (bloc) => bloc.add(LoadDashboard()),
    expect: () => [
      isA<DashboardState>()
          .having((s) => s.viewStatus, 'status', ViewStatus.success)
          .having((s) => s.isStale, 'stale', true)
          .having((s) => s.stats?.tournamentsJoined, 'cached', 5),
      isA<DashboardState>()
          .having((s) => s.viewStatus, 'status', ViewStatus.success)
          .having((s) => s.isStale, 'stale', true)
          .having((s) => s.errorMessage, 'errorMessage', contains('network'))
          .having((s) => s.stats?.tournamentsJoined, 'cached', 5),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'LoadDashboard emit failure khi user chưa đăng nhập',
    build: () {
      when(() => auth.currentUser).thenReturn(null);
      return build();
    },
    act: (bloc) => bloc.add(LoadDashboard()),
    expect: () => [
      isA<DashboardState>()
          .having((s) => s.viewStatus, 'status', ViewStatus.failure)
          .having(
            (s) => s.errorMessage,
            'errorMessage',
            'Người dùng chưa đăng nhập',
          ),
    ],
  );

  blocTest<DashboardBloc, DashboardState>(
    'LoadDashboard không load lại khi đang loading',
    seed: () => const DashboardState(viewStatus: ViewStatus.loading),
    build: () => build(),
    act: (bloc) => bloc.add(LoadDashboard()),
    expect: () => <DashboardState>[],
    verify: (_) {
      verifyNever(() => repo.getSummary(any()));
    },
  );

  blocTest<DashboardBloc, DashboardState>(
    'RefreshDashboard force recompute và đợi snapshot mới (skip current)',
    setUp: () async {
      await cache.write(
        'u1',
        const DashboardStats(
          tournamentsJoined: 1,
          finishedTournaments: 0,
          championCount: 0,
          runnerUpCount: 0,
          lastChampionAt: null,
          recentMatches: [],
        ),
      );
    },
    build: () {
      when(() => repo.requestRecompute('u1')).thenAnswer((_) async {});
      final controller = StreamController<GNUserStatsSummary?>();
      // First emission = current/stale doc; bloc must skip it.
      // Second emission = the new doc the function writes.
      Future.delayed(const Duration(milliseconds: 30), () {
        controller.add(_summary(tournamentsJoined: 1));
        controller.add(_summary(tournamentsJoined: 7));
      });
      when(
        () => repo.listenSummary('u1'),
      ).thenAnswer((_) => controller.stream);
      return build();
    },
    act: (bloc) => bloc.add(RefreshDashboard()),
    wait: const Duration(milliseconds: 200),
    expect: () => [
      isA<DashboardState>().having(
        (s) => s.viewStatus,
        'status',
        ViewStatus.loading,
      ),
      isA<DashboardState>()
          .having((s) => s.viewStatus, 'status', ViewStatus.success)
          .having((s) => s.stats?.tournamentsJoined, 'joined', 7),
    ],
    verify: (_) {
      verify(() => repo.requestRecompute('u1')).called(1);
      verifyNever(() => repo.getSummary(any()));
    },
  );

  test('DashboardStats derived metrics tính đúng', () {
    const empty = DashboardStats(
      tournamentsJoined: 0,
      finishedTournaments: 0,
      championCount: 0,
      runnerUpCount: 0,
      lastChampionAt: null,
      recentMatches: [],
    );
    expect(empty.winRate, isNull);
    expect(empty.championRate, isNull);
    expect(empty.runnerUpRate, isNull);
    expect(empty.goalDifference, 0);

    const full = DashboardStats(
      tournamentsJoined: 4,
      finishedTournaments: 2,
      championCount: 1,
      runnerUpCount: 1,
      lastChampionAt: null,
      recentMatches: [],
      matchesPlayed: 10,
      wins: 6,
      draws: 2,
      losses: 2,
      goals: 18,
      goalsConceded: 9,
    );
    expect(full.winRate, closeTo(0.6, 1e-9));
    expect(full.championRate, closeTo(0.5, 1e-9));
    expect(full.runnerUpRate, closeTo(0.5, 1e-9));
    expect(full.goalDifference, 9);
  });

  test('Recent matches: chọn top 10 theo date, sort hiển thị theo updatedAt',
      () async {
    // Tạo 12 match với date giảm dần (newest = m0); m0..m9 vào top 10 theo date.
    // m11 (date cũ nhất) bị loại dù updatedAt mới — đúng với "lấy theo ngày".
    // Trong top 10: m9 có updatedAt mới nhất → phải đứng đầu.
    final matches = <GNUserRecentMatch>[
      for (var i = 0; i < 12; i++)
        _recent(
          matchId: 'm$i',
          date: DateTime(2026, 5, 12 - i),
          updatedAt: i == 9
              ? DateTime(2026, 6, 1)
              : i == 11
                  ? DateTime(2026, 7, 1)
                  : DateTime(2026, 5, 12 - i),
        ),
    ];
    when(() => repo.getSummary('u1'))
        .thenAnswer((_) async => _summary(recentMatches: matches));
    final bloc = build();
    bloc.add(LoadDashboard());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final ids =
        bloc.state.stats!.recentMatches.map((m) => m.matchId).toList();
    expect(ids.length, 10);
    expect(ids.contains('m11'), isFalse,
        reason: 'm11 cũ nhất theo date → ngoài top 10');
    expect(ids.first, 'm9',
        reason: 'm9 có updatedAt mới nhất trong top 10 theo date');
    await bloc.close();
  });

  test('League performance: 2 entries không có lastPlayedAt giữ thứ tự nhập',
      () async {
    final history = [
      GNUserLeaguePerformance(
        leagueId: 'lA',
        leagueName: 'A',
        lastPlayedAt: null,
        matchesPlayed: 1,
        wins: 1,
        draws: 0,
        losses: 0,
        goals: 1,
        goalsConceded: 0,
      ),
      GNUserLeaguePerformance(
        leagueId: 'lB',
        leagueName: 'B',
        lastPlayedAt: null,
        matchesPlayed: 1,
        wins: 0,
        draws: 1,
        losses: 0,
        goals: 1,
        goalsConceded: 1,
      ),
    ];
    when(
      () => repo.getSummary('u1'),
    ).thenAnswer((_) async => _summary().copyWithHistory(history));
    final bloc = build();
    bloc.add(LoadDashboard());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(bloc.state.stats!.leaguePerformance.length, 2);
    await bloc.close();
  });

  test('League performance: ad-null vs bd-non-null đặt null lên trước (comparator branch)',
      () async {
    // Two items only, ordered [hasDate, null] — sort must call
    // comparator(hasDate, null) → +1 path on line 188 AND swap, then
    // possibly comparator(null, hasDate) → -1 path on line 187.
    final history = [
      GNUserLeaguePerformance(
        leagueId: 'lDate',
        leagueName: 'D',
        lastPlayedAt: DateTime(2026, 5, 1),
        matchesPlayed: 1,
        wins: 1,
        draws: 0,
        losses: 0,
        goals: 1,
        goalsConceded: 0,
      ),
      GNUserLeaguePerformance(
        leagueId: 'lNull',
        leagueName: 'N',
        lastPlayedAt: null,
        matchesPlayed: 1,
        wins: 0,
        draws: 0,
        losses: 1,
        goals: 0,
        goalsConceded: 1,
      ),
    ];
    when(
      () => repo.getSummary('u1'),
    ).thenAnswer((_) async => _summary().copyWithHistory(history));
    final bloc = build();
    bloc.add(LoadDashboard());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final ids = bloc.state.stats!.leaguePerformance
        .map((e) => e.leagueId)
        .toList();
    expect(ids, ['lNull', 'lDate']);
    await bloc.close();
  });

  test('League performance: 3 entries [date1, null, date2] để hit cả 2 branch null',
      () async {
    final history = [
      GNUserLeaguePerformance(
        leagueId: 'lD1',
        leagueName: 'D1',
        lastPlayedAt: DateTime(2026, 5, 1),
        matchesPlayed: 1,
        wins: 1,
        draws: 0,
        losses: 0,
        goals: 1,
        goalsConceded: 0,
      ),
      GNUserLeaguePerformance(
        leagueId: 'lN',
        leagueName: 'N',
        lastPlayedAt: null,
        matchesPlayed: 1,
        wins: 0,
        draws: 1,
        losses: 0,
        goals: 1,
        goalsConceded: 1,
      ),
      GNUserLeaguePerformance(
        leagueId: 'lD2',
        leagueName: 'D2',
        lastPlayedAt: DateTime(2026, 6, 1),
        matchesPlayed: 1,
        wins: 1,
        draws: 0,
        losses: 0,
        goals: 2,
        goalsConceded: 1,
      ),
    ];
    when(
      () => repo.getSummary('u1'),
    ).thenAnswer((_) async => _summary().copyWithHistory(history));
    final bloc = build();
    bloc.add(LoadDashboard());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final ids = bloc.state.stats!.leaguePerformance
        .map((e) => e.leagueId)
        .toList();
    expect(ids, ['lN', 'lD1', 'lD2']);
    await bloc.close();
  });

  test('League performance: 4 entries để buộc sort gọi cả 2 nhánh null', () async {
    final history = [
      GNUserLeaguePerformance(
        leagueId: 'lD3',
        leagueName: 'D3',
        lastPlayedAt: DateTime(2026, 7, 1),
        matchesPlayed: 1,
        wins: 1,
        draws: 0,
        losses: 0,
        goals: 1,
        goalsConceded: 0,
      ),
      GNUserLeaguePerformance(
        leagueId: 'lD2',
        leagueName: 'D2',
        lastPlayedAt: DateTime(2026, 6, 1),
        matchesPlayed: 1,
        wins: 1,
        draws: 0,
        losses: 0,
        goals: 1,
        goalsConceded: 0,
      ),
      GNUserLeaguePerformance(
        leagueId: 'lD1',
        leagueName: 'D1',
        lastPlayedAt: DateTime(2026, 5, 1),
        matchesPlayed: 1,
        wins: 1,
        draws: 0,
        losses: 0,
        goals: 1,
        goalsConceded: 0,
      ),
      GNUserLeaguePerformance(
        leagueId: 'lN',
        leagueName: 'N',
        lastPlayedAt: null,
        matchesPlayed: 1,
        wins: 0,
        draws: 1,
        losses: 0,
        goals: 1,
        goalsConceded: 1,
      ),
    ];
    when(
      () => repo.getSummary('u1'),
    ).thenAnswer((_) async => _summary().copyWithHistory(history));
    final bloc = build();
    bloc.add(LoadDashboard());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(
      bloc.state.stats!.leaguePerformance.map((e) => e.leagueId).toList(),
      ['lN', 'lD1', 'lD2', 'lD3'],
    );
    await bloc.close();
  });

  test('League performance: sort theo lastPlayedAt asc, null lên đầu, giữ derived',
      () async {
    final history = [
      GNUserLeaguePerformance(
        leagueId: 'lB',
        leagueName: 'B',
        lastPlayedAt: DateTime(2026, 5, 1),
        matchesPlayed: 4,
        wins: 2,
        draws: 1,
        losses: 1,
        goals: 6,
        goalsConceded: 5,
      ),
      GNUserLeaguePerformance(
        leagueId: 'lA',
        leagueName: 'A',
        lastPlayedAt: DateTime(2026, 3, 1),
        matchesPlayed: 3,
        wins: 3,
        draws: 0,
        losses: 0,
        goals: 9,
        goalsConceded: 1,
      ),
      GNUserLeaguePerformance(
        leagueId: 'lZ',
        leagueName: 'Z',
        lastPlayedAt: null,
        matchesPlayed: 0,
        wins: 0,
        draws: 0,
        losses: 0,
        goals: 0,
        goalsConceded: 0,
      ),
    ];
    when(
      () => repo.getSummary('u1'),
    ).thenAnswer((_) async => _summary().copyWithHistory(history));
    final bloc = build();
    bloc.add(LoadDashboard());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final perf = bloc.state.stats!.leaguePerformance;
    expect(perf.map((e) => e.leagueId).toList(), ['lZ', 'lA', 'lB']);
    expect(perf[1].pointsPerMatch, closeTo(3.0, 1e-9));
    expect(perf[1].goalDifferencePerMatch, closeTo(8 / 3, 1e-9));
    await bloc.close();
  });

  test('compareByLastPlayed: tất cả 4 nhánh null/non-null', () {
    final withDate = GNUserLeaguePerformance(
      leagueId: 'a',
      leagueName: '',
      lastPlayedAt: DateTime(2026, 1, 1),
      matchesPlayed: 0,
      wins: 0,
      draws: 0,
      losses: 0,
      goals: 0,
      goalsConceded: 0,
    );
    final withDateLater = GNUserLeaguePerformance(
      leagueId: 'b',
      leagueName: '',
      lastPlayedAt: DateTime(2026, 6, 1),
      matchesPlayed: 0,
      wins: 0,
      draws: 0,
      losses: 0,
      goals: 0,
      goalsConceded: 0,
    );
    final noDate = GNUserLeaguePerformance(
      leagueId: 'c',
      leagueName: '',
      lastPlayedAt: null,
      matchesPlayed: 0,
      wins: 0,
      draws: 0,
      losses: 0,
      goals: 0,
      goalsConceded: 0,
    );
    expect(DashboardBloc.compareByLastPlayed(noDate, noDate), 0);
    expect(DashboardBloc.compareByLastPlayed(noDate, withDate), -1);
    expect(DashboardBloc.compareByLastPlayed(withDate, noDate), 1);
    expect(
      DashboardBloc.compareByLastPlayed(withDate, withDateLater),
      lessThan(0),
    );
  });

  test('Map h2hSummary sang OpponentStat', () async {
    when(() => repo.getSummary('u1')).thenAnswer(
      (_) async => _summary().copyWithBasic(
        h2hSummary: [
          const GNUserOpponentStat(
            opponentId: 'u2',
            opponentDisplayName: 'P2',
            matchesPlayed: 8,
            wins: 5,
            draws: 1,
            losses: 2,
          ),
        ],
      ),
    );
    final bloc = build();
    bloc.add(LoadDashboard());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final ops = bloc.state.stats!.opponents;
    expect(ops.length, 1);
    expect(ops.first.opponentDisplayName, 'P2');
    expect(ops.first.wins, 5);
    expect(ops.first.rate(5), closeTo(5 / 8, 1e-9));
    await bloc.close();
  });

  test('Map mỗi GNRecentMatchResult sang MatchResult tương ứng', () async {
    when(() => repo.getSummary('u1')).thenAnswer(
      (_) async => _summary(
        recentMatches: [
          _recent(matchId: 'mw', result: GNRecentMatchResult.win),
          _recent(matchId: 'md', result: GNRecentMatchResult.draw),
          _recent(matchId: 'ml', result: GNRecentMatchResult.loss),
        ],
      ),
    );
    final bloc = build();
    bloc.add(LoadDashboard());
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final mapped =
        bloc.state.stats!.recentMatches.map((m) => m.result).toList();
    expect(mapped, [MatchResult.win, MatchResult.draw, MatchResult.loss]);
    await bloc.close();
  });
}
