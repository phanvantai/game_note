import 'package:equatable/equatable.dart';
import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/domain/entities/league_model.dart';
import 'package:game_note/domain/entities/player_model.dart';

class PlayerStatsModel extends Equatable {
  final int? id;
  final PlayerModel playerModel;
  final LeagueModel leagueModel;
  final int totalPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int goalDifferent;
  final int points;

  const PlayerStatsModel({
    this.id,
    required this.playerModel,
    required this.leagueModel,
    this.totalPlayed = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
    this.goalDifferent = 0,
    this.points = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      DBTableColumn.playerLeagueId: id,
      DBTableColumn.playerId: playerModel.id,
      DBTableColumn.leagueId: leagueModel.id,
      DBTableColumn.playerLeagueTotal: totalPlayed,
      DBTableColumn.playerLeagueWins: wins,
      DBTableColumn.playerLeagueDraws: draws,
      DBTableColumn.playerLeagueLosses: losses,
      DBTableColumn.playerLeagueGD: goalDifferent,
      DBTableColumn.playerLeaguePoints: points,
    };
  }

  @override
  List<Object?> get props => [
        id,
        playerModel,
        leagueModel,
        totalPlayed,
        wins,
        draws,
        losses,
        goalDifferent,
        points
      ];
}
