import 'package:equatable/equatable.dart';

enum MatchResult { win, draw, loss }

class RecentMatchSummary extends Equatable {
  final String matchId;
  final String leagueId;
  final String leagueName;
  final DateTime date;
  final int userScore;
  final int opponentScore;
  final String opponentDisplayName;
  final MatchResult result;

  const RecentMatchSummary({
    required this.matchId,
    required this.leagueId,
    required this.leagueName,
    required this.date,
    required this.userScore,
    required this.opponentScore,
    required this.opponentDisplayName,
    required this.result,
  });

  @override
  List<Object?> get props => [
    matchId,
    leagueId,
    leagueName,
    date,
    userScore,
    opponentScore,
    opponentDisplayName,
    result,
  ];
}
