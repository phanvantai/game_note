import 'package:equatable/equatable.dart';

/// One point on the per-league performance chart.
///
/// `pointsPerMatch` and `goalDifferencePerMatch` are null when the user
/// hasn't actually played a match in the league yet — caller should drop
/// nulls before plotting (avoids drawing a misleading 0).
class LeaguePerformancePoint extends Equatable {
  final String leagueId;
  final String leagueName;
  final DateTime? lastPlayedAt;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final double? pointsPerMatch;
  final double? goalDifferencePerMatch;

  const LeaguePerformancePoint({
    required this.leagueId,
    required this.leagueName,
    required this.lastPlayedAt,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.pointsPerMatch,
    required this.goalDifferencePerMatch,
  });

  @override
  List<Object?> get props => [
    leagueId,
    leagueName,
    lastPlayedAt,
    matchesPlayed,
    wins,
    draws,
    losses,
    pointsPerMatch,
    goalDifferencePerMatch,
  ];
}
