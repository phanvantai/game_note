import 'package:equatable/equatable.dart';

import 'recent_match_summary.dart';

class DashboardStats extends Equatable {
  final int tournamentsJoined;
  final int finishedTournaments;
  final int championCount;
  final int runnerUpCount;
  final DateTime? lastChampionAt;
  final List<RecentMatchSummary> recentMatches;

  const DashboardStats({
    required this.tournamentsJoined,
    required this.finishedTournaments,
    required this.championCount,
    required this.runnerUpCount,
    required this.lastChampionAt,
    required this.recentMatches,
  });

  @override
  List<Object?> get props => [
    tournamentsJoined,
    finishedTournaments,
    championCount,
    runnerUpCount,
    lastChampionAt,
    recentMatches,
  ];
}
