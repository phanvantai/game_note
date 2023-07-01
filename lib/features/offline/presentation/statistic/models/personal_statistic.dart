import 'package:equatable/equatable.dart';
import 'package:game_note/features/offline/domain/entities/league_model.dart';
import 'package:game_note/features/offline/domain/entities/player_model.dart';
import 'package:game_note/features/offline/domain/entities/player_stats_model.dart';

class PersonalStatistic extends Equatable {
  final PlayerModel playerModel;
  final int countWinsLeague;
  final int countJoin;
  final int countMatches;
  final int countPoints;
  final int countWins;
  final int countDraws;
  final int countLoses;
  final int countGD;

  const PersonalStatistic({
    this.countWinsLeague = 0,
    this.countJoin = 0,
    this.countMatches = 0,
    this.countPoints = 0,
    this.countWins = 0,
    this.countDraws = 0,
    this.countLoses = 0,
    this.countGD = 0,
    required this.playerModel,
  });

  PersonalStatistic copyWith({
    PlayerModel? playerModel,
    int? countWinsLeague,
    int? countJoin,
    int? countMatches,
    int? countPoints,
    int? countWins,
    int? countDraws,
    int? countLoses,
    int? countGD,
  }) {
    return PersonalStatistic(
      playerModel: playerModel ?? this.playerModel,
      countDraws: countDraws ?? this.countDraws,
      countGD: countGD ?? this.countGD,
      countJoin: countJoin ?? this.countJoin,
      countLoses: countLoses ?? this.countLoses,
      countMatches: countMatches ?? this.countMatches,
      countPoints: countPoints ?? this.countWins,
      countWins: countWins ?? this.countWins,
      countWinsLeague: countWinsLeague ?? this.countWinsLeague,
    );
  }

  @override
  List<Object?> get props => [
        playerModel,
        countWinsLeague,
        countJoin,
        countMatches,
        countPoints,
        countWins,
        countDraws,
        countLoses,
        countGD,
      ];

  PersonalStatistic getStatisticWithLeague(LeagueModel leagueModel) {
    final playerStats = leagueModel.statsWithPlayer(playerModel);
    if (playerStats != null) {
      return copyWith(
        countJoin: countJoin + 1,
        countWinsLeague:
            countWinsLeague + (leagueModel.isChampion(playerModel) ? 1 : 0),
        countDraws: countDraws + playerStats.draws,
        countGD: countGD + playerStats.goalDifferent,
        countLoses: countLoses + playerStats.losses,
        countWins: countWins + playerStats.wins,
        countMatches: countMatches + playerStats.totalPlayed,
        countPoints: countPoints + playerStats.points,
      );
    } else {
      return this;
    }
  }

  int get percentWin {
    if (countMatches < 1) {
      return 0;
    }
    return ((countWins / countMatches) * 100).round();
  }

  int get percentDraw {
    if (countMatches < 1) {
      return 0;
    }
    return ((countDraws / countMatches) * 100).round();
  }

  int get percentLose {
    if (countMatches < 1) {
      return 0;
    }
    return ((countLoses / countMatches) * 100).round();
  }

  double get pointPerMatch {
    if (countMatches < 1) {
      return 0;
    }
    return countPoints / countMatches;
  }

  int get totalWinsDrawLose {
    return countWins + countDraws + countLoses;
  }
}

extension LeagueModelX on LeagueModel {
  PlayerStatsModel? statsWithPlayer(PlayerModel playerModel) {
    final filter =
        players.where((element) => element.playerModel.id == playerModel.id);
    return filter.isNotEmpty ? filter.first : null;
  }

  bool isChampion(PlayerModel playerModel) {
    return players.isNotEmpty && players[0].playerModel.id == playerModel.id;
  }
}
