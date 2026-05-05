import 'package:equatable/equatable.dart';

import 'league_performance_point.dart';
import 'opponent_stat.dart';
import 'recent_match_summary.dart';

class DashboardStats extends Equatable {
  final int tournamentsJoined;
  final int finishedTournaments;
  final int championCount;
  final int runnerUpCount;
  final DateTime? lastChampionAt;

  // Lifetime match aggregates (across every league user has played).
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goals;
  final int goalsConceded;

  final List<RecentMatchSummary> recentMatches;

  /// Per-league performance points, sorted oldest → newest. UI charts the
  /// last N entries; bloc passes the data raw so the chart widget owns the
  /// "how many to show" decision.
  final List<LeaguePerformancePoint> leaguePerformance;

  /// Per-opponent head-to-head records. Used by the "đối đầu" section to
  /// surface the opponent the user has won/drawn/lost most matches against.
  final List<OpponentStat> opponents;

  const DashboardStats({
    required this.tournamentsJoined,
    required this.finishedTournaments,
    required this.championCount,
    required this.runnerUpCount,
    required this.lastChampionAt,
    required this.recentMatches,
    this.matchesPlayed = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goals = 0,
    this.goalsConceded = 0,
    this.leaguePerformance = const [],
    this.opponents = const [],
  });

  double? get winRate => matchesPlayed == 0 ? null : wins / matchesPlayed;
  int get goalDifference => goals - goalsConceded;
  double? get championRate =>
      finishedTournaments == 0 ? null : championCount / finishedTournaments;
  double? get runnerUpRate =>
      finishedTournaments == 0 ? null : runnerUpCount / finishedTournaments;

  @override
  List<Object?> get props => [
    tournamentsJoined,
    finishedTournaments,
    championCount,
    runnerUpCount,
    lastChampionAt,
    matchesPlayed,
    wins,
    draws,
    losses,
    goals,
    goalsConceded,
    recentMatches,
    leaguePerformance,
    opponents,
  ];
}
