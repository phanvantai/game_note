import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/cache/dashboard_cache.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/domain/repositories/user_stats_repository.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/stats/gn_user_stats_summary.dart';

import '../models/dashboard_stats.dart';
import '../models/league_performance_point.dart';
import '../models/opponent_stat.dart';
import '../models/recent_match_summary.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

/// Loads the dashboard from a single Firestore doc
/// (`users/{uid}/stats/summary`) instead of fanning out across every league
/// the user has joined. The summary is maintained server-side by the
/// `onLeagueMatchWritten` Cloud Function.
///
/// First-paint UX: if a cached snapshot exists locally, render it
/// immediately with `isStale = true`, then refresh in the background.
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final UserStatsRepository _repo;
  final GNAuth _auth;
  final DashboardCache _cache;
  final GNFirestore _firestore;
  final Duration _recomputeTimeout;

  DashboardBloc({
    required UserStatsRepository userStatsRepository,
    required GNAuth auth,
    required DashboardCache cache,
    required GNFirestore firestore,
    Duration recomputeTimeout = const Duration(seconds: 30),
  }) : _repo = userStatsRepository,
       _auth = auth,
       _cache = cache,
       _firestore = firestore,
       _recomputeTimeout = recomputeTimeout,
       super(const DashboardState()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.viewStatus == ViewStatus.loading) return;
    await _load(emit, fromRefresh: false);
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    // Pull-to-refresh asks the server for a fresh fold of the user's
    // matches. This is heavier than a normal load (it re-runs the backfill
    // function) but is the only way to recover from drift or pick up
    // schema changes for an already-built summary doc.
    await _load(emit, fromRefresh: true, forceRecompute: true);
  }

  Future<void> _load(
    Emitter<DashboardState> emit, {
    required bool fromRefresh,
    bool forceRecompute = false,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: 'Người dùng chưa đăng nhập',
        ),
      );
      return;
    }

    // First paint: hydrate from cache when available, otherwise show loading.
    // On explicit refresh skip the cache hit and just go to loading — the
    // user expects a refresh to actually fetch.
    if (!fromRefresh) {
      final cached = await _cache.read(uid);
      if (cached != null) {
        emit(
          state.copyWith(
            viewStatus: ViewStatus.success,
            stats: cached,
            isStale: true,
            errorMessage: '',
          ),
        );
      } else {
        emit(state.copyWith(viewStatus: ViewStatus.loading));
      }
    } else {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.loading,
          // keep prior stats so the UI doesn't blank out during a pull-to-refresh
        ),
      );
    }

    try {
      GNUserStatsSummary? summary;
      if (forceRecompute) {
        // Trigger a server rebuild and wait for the next snapshot. We skip
        // the first emission (the current/stale doc) and take whatever the
        // function writes next.
        await _repo.requestRecompute(uid);
        summary = await _repo
            .listenSummary(uid)
            .skip(1)
            .where((s) => s != null)
            .cast<GNUserStatsSummary>()
            .first
            .timeout(_recomputeTimeout);
      } else {
        summary = await _repo.getSummary(uid);
        // Lazy backfill: users who joined before this feature shipped
        // won't have a summary doc. Ask the server to build one.
        if (summary == null) {
          await _repo.requestRecompute(uid);
          summary = await _repo
              .listenSummary(uid)
              .where((s) => s != null)
              .cast<GNUserStatsSummary>()
              .first
              .timeout(_recomputeTimeout);
        }
      }

      final stats = await _toDashboardStats(summary);
      await _cache.write(uid, stats);
      emit(
        state.copyWith(
          viewStatus: ViewStatus.success,
          stats: stats,
          isStale: false,
          errorMessage: '',
        ),
      );
    } catch (e) {
      if (state.stats != null) {
        // Don't blow away cached stats on transient errors.
        emit(state.copyWith(isStale: true, errorMessage: e.toString()));
      } else {
        emit(
          state.copyWith(
            viewStatus: ViewStatus.failure,
            errorMessage: e.toString(),
          ),
        );
      }
    }
  }

  Future<DashboardStats> _toDashboardStats(GNUserStatsSummary s) async {
    final allIds = {
      ...s.h2hSummary.map((o) => o.opponentId),
      ...s.recentMatches.map((m) => m.opponentId),
    }.toList();
    final usersMap = allIds.isEmpty
        ? <String, dynamic>{}
        : await _firestore.getUsersById(allIds);

    return DashboardStats(
      tournamentsJoined: s.tournamentsJoined,
      finishedTournaments: s.tournamentsFinished,
      championCount: s.championCount,
      runnerUpCount: s.runnerUpCount,
      lastChampionAt: s.lastChampionAt,
      matchesPlayed: s.matchesPlayed,
      wins: s.wins,
      draws: s.draws,
      losses: s.losses,
      goals: s.goals,
      goalsConceded: s.goalsConceded,
      leaguePerformance: _toLeaguePerformance(s.leagueHistory),
      opponents: s.h2hSummary
          .map(
            (o) => OpponentStat(
              opponentId: o.opponentId,
              opponentDisplayName: o.opponentDisplayName,
              opponentPhotoUrl: usersMap[o.opponentId]?.photoUrl,
              matchesPlayed: o.matchesPlayed,
              wins: o.wins,
              draws: o.draws,
              losses: o.losses,
            ),
          )
          .toList(),
      // Function stores up to 20 most-recent-by-date matches as a buffer.
      // We pick the top 10 by play date, then re-sort by `updatedAt` so the
      // UI surfaces matches that were edited most recently first (handy
      // when an admin enters a result for an older fixture).
      recentMatches: _selectRecentMatches(s.recentMatches, usersMap),
    );
  }

  /// Compare two performance entries by `lastPlayedAt` ascending. Null
  /// dates sort to the front (treated as "oldest possible"). Exposed as
  /// `@visibleForTesting` so the null-handling branches are directly
  /// covered without depending on Dart's sort call patterns.
  @visibleForTesting
  static int compareByLastPlayed(
    GNUserLeaguePerformance a,
    GNUserLeaguePerformance b,
  ) {
    final ad = a.lastPlayedAt;
    final bd = b.lastPlayedAt;
    if (ad == null && bd == null) return 0;
    if (ad == null) return -1;
    if (bd == null) return 1;
    return ad.compareTo(bd);
  }

  List<LeaguePerformancePoint> _toLeaguePerformance(
    List<GNUserLeaguePerformance> history,
  ) {
    final sorted = [...history]..sort(compareByLastPlayed);
    return sorted
        .map(
          (e) => LeaguePerformancePoint(
            leagueId: e.leagueId,
            leagueName: e.leagueName,
            lastPlayedAt: e.lastPlayedAt,
            matchesPlayed: e.matchesPlayed,
            wins: e.wins,
            draws: e.draws,
            losses: e.losses,
            pointsPerMatch: e.pointsPerMatch,
            goalDifferencePerMatch: e.goalDifferencePerMatch,
          ),
        )
        .toList();
  }

  List<RecentMatchSummary> _selectRecentMatches(
    List<GNUserRecentMatch> all,
    Map<String, dynamic> usersMap,
  ) {
    final top = [...all]..sort((a, b) => b.date.compareTo(a.date));
    final picked = top.take(10).toList()
      ..sort((a, b) {
        final au = a.updatedAt ?? a.date;
        final bu = b.updatedAt ?? b.date;
        return bu.compareTo(au);
      });
    return picked.map((m) => _toRecentMatch(m, usersMap)).toList();
  }

  RecentMatchSummary _toRecentMatch(
    GNUserRecentMatch m,
    Map<String, dynamic> usersMap,
  ) {
    return RecentMatchSummary(
      matchId: m.matchId,
      leagueId: m.leagueId,
      leagueName: m.leagueName,
      date: m.date,
      userScore: m.userScore,
      opponentScore: m.opponentScore,
      opponentDisplayName: m.opponentDisplayName,
      opponentPhotoUrl: usersMap[m.opponentId]?.photoUrl,
      result: _mapResult(m.result),
    );
  }

  MatchResult _mapResult(GNRecentMatchResult r) {
    switch (r) {
      case GNRecentMatchResult.win:
        return MatchResult.win;
      case GNRecentMatchResult.draw:
        return MatchResult.draw;
      case GNRecentMatchResult.loss:
        return MatchResult.loss;
    }
  }
}
