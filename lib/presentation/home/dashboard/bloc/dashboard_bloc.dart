import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';

import '../models/dashboard_stats.dart';
import '../models/recent_match_summary.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final EsportLeagueRepository _leagueRepository;
  final GNAuth _auth;

  DashboardBloc({
    required EsportLeagueRepository leagueRepository,
    required GNAuth auth,
  }) : _leagueRepository = leagueRepository,
       _auth = auth,
       super(const DashboardState()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<RefreshDashboard>(_onRefreshDashboard);
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    if (state.viewStatus == ViewStatus.loading) return;
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    await _load(emit);
  }

  Future<void> _onRefreshDashboard(
    RefreshDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(viewStatus: ViewStatus.loading));
    await _load(emit);
  }

  Future<void> _load(Emitter<DashboardState> emit) async {
    try {
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

      final leagues = (await _leagueRepository.getMyLeagues())
          .where((league) => league.participants.contains(uid))
          .toList();

      final detailResults = await Future.wait(
        leagues.map(
          (league) async => _LeagueDashboardData(
            league: league,
            data: await _leagueRepository.getParticipantsAndMatches(league.id),
          ),
        ),
      );

      var finishedTournaments = 0;
      var championCount = 0;
      var runnerUpCount = 0;
      DateTime? lastChampionAt;
      final summaries = <RecentMatchSummary>[];

      for (final result in detailResults) {
        final league = result.league;
        final participants = [...result.data.participants]
          ..sort(_compareStandings);
        final rank = participants.indexWhere((stat) => stat.userId == uid);

        if (league.status == GNEsportLeagueStatus.finished.value &&
            rank != -1) {
          finishedTournaments++;
          if (rank == 0) {
            championCount++;
            final championAt = league.endDate ?? league.startDate;
            if (lastChampionAt == null || championAt.isAfter(lastChampionAt)) {
              lastChampionAt = championAt;
            }
          } else if (rank == 1) {
            runnerUpCount++;
          }
        }

        summaries.addAll(
          result.data.matches
              .where((match) => _isFinishedUserMatch(match, uid))
              .map((match) => _summaryForMatch(match, league.name, uid)),
        );
      }

      summaries.sort((a, b) => b.date.compareTo(a.date));
      emit(
        state.copyWith(
          viewStatus: ViewStatus.success,
          stats: DashboardStats(
            tournamentsJoined: leagues.length,
            finishedTournaments: finishedTournaments,
            championCount: championCount,
            runnerUpCount: runnerUpCount,
            lastChampionAt: lastChampionAt,
            recentMatches: summaries.take(10).toList(),
          ),
          errorMessage: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          viewStatus: ViewStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  int _compareStandings(GNEsportLeagueStat a, GNEsportLeagueStat b) {
    if (a.points != b.points) return b.points.compareTo(a.points);
    if (a.goalDifference != b.goalDifference) {
      return b.goalDifference.compareTo(a.goalDifference);
    }
    return b.goals.compareTo(a.goals);
  }

  bool _isFinishedUserMatch(GNEsportMatch match, String uid) {
    return match.isFinished &&
        (match.homeTeamId == uid || match.awayTeamId == uid);
  }

  RecentMatchSummary _summaryForMatch(
    GNEsportMatch match,
    String leagueName,
    String uid,
  ) {
    final isHome = match.homeTeamId == uid;
    final userScore = isHome ? match.homeScore ?? 0 : match.awayScore ?? 0;
    final opponentScore = isHome ? match.awayScore ?? 0 : match.homeScore ?? 0;
    final opponent = isHome ? match.awayTeam : match.homeTeam;

    return RecentMatchSummary(
      matchId: match.id,
      leagueId: match.leagueId,
      leagueName: leagueName,
      date: match.date,
      userScore: userScore,
      opponentScore: opponentScore,
      opponentDisplayName: opponent?.displayName ?? 'Đối thủ',
      result: userScore > opponentScore
          ? MatchResult.win
          : userScore == opponentScore
          ? MatchResult.draw
          : MatchResult.loss,
    );
  }
}

class _LeagueDashboardData {
  final GNEsportLeague league;
  final LeagueDetailData data;

  const _LeagueDashboardData({required this.league, required this.data});
}
