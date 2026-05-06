import 'package:equatable/equatable.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

enum GroupAwardKind {
  champion,
  runnerUp,
  drawKing,
  ironDefense,
  master,
}

class GroupAward extends Equatable {
  final GroupAwardKind kind;
  final GNUser player;

  /// Primary metric value:
  /// - For champion / runnerUp / master: rate in 0..1
  /// - For ironDefense: goals conceded per match (>=0)
  /// - For drawKing: integer count expressed as double
  final double value;

  /// Sample size used to qualify / display "(x/y)".
  /// For champion / runnerUp: finished leagues joined.
  /// For master / ironDefense: matches played.
  /// For drawKing: matches played (pure context, not a threshold gate).
  final int sampleSize;

  /// Numerator that produced the rate, for "8/12" style display.
  /// drawKing: same as value. ironDefense: goalsConceded total.
  final int numerator;

  const GroupAward({
    required this.kind,
    required this.player,
    required this.value,
    required this.sampleSize,
    required this.numerator,
  });

  @override
  List<Object?> get props => [kind, player.id, value, sampleSize, numerator];
}

class GroupPlayerStats extends Equatable {
  final GNUser player;
  final int matches;
  final int wins;
  final int draws;
  final int losses;
  final int goals;
  final int goalsConceded;

  const GroupPlayerStats({
    required this.player,
    required this.matches,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goals,
    required this.goalsConceded,
  });

  double get winRate => matches == 0 ? 0 : wins / matches;
  double get drawRate => matches == 0 ? 0 : draws / matches;
  double get lossRate => matches == 0 ? 0 : losses / matches;
  int get goalDifference => goals - goalsConceded;

  @override
  List<Object?> get props => [
        player.id,
        matches,
        wins,
        draws,
        losses,
        goals,
        goalsConceded,
      ];
}

class GroupOverview extends Equatable {
  final int totalLeagues;
  final int finishedLeagues;
  final int totalMatchesPlayed;
  final int totalGoals;

  final GroupAward? champion; // vô đối
  final GroupAward? runnerUpKing; // kẻ về nhì vĩ đại
  final GroupAward? drawKing; // hoà vương
  final GroupAward? ironDefense; // hàng thủ thép
  final GroupAward? master; // cao thủ

  /// Sorted by win rate desc, matches desc.
  final List<GroupPlayerStats> playerStats;

  const GroupOverview({
    required this.totalLeagues,
    required this.finishedLeagues,
    required this.totalMatchesPlayed,
    required this.totalGoals,
    required this.champion,
    required this.runnerUpKing,
    required this.drawKing,
    required this.ironDefense,
    required this.master,
    required this.playerStats,
  });

  const GroupOverview.empty()
      : totalLeagues = 0,
        finishedLeagues = 0,
        totalMatchesPlayed = 0,
        totalGoals = 0,
        champion = null,
        runnerUpKing = null,
        drawKing = null,
        ironDefense = null,
        master = null,
        playerStats = const [];

  bool get hasAnyAward =>
      champion != null ||
      runnerUpKing != null ||
      drawKing != null ||
      ironDefense != null ||
      master != null;

  @override
  List<Object?> get props => [
        totalLeagues,
        finishedLeagues,
        totalMatchesPlayed,
        totalGoals,
        champion,
        runnerUpKing,
        drawKing,
        ironDefense,
        master,
        playerStats,
      ];
}
