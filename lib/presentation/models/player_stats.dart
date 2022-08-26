import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/domain/entities/player_stats_model.dart';

class PlayerStats extends Equatable {
  final String rank;
  final String name;
  final String played;
  final String wins;
  final String draws;
  final String losses;
  final int goalsDifference;
  final int points;
  final Color color;

  const PlayerStats(this.rank, this.name, this.played, this.wins, this.draws,
      this.losses, this.goalsDifference, this.points, this.color);

  @override
  List<Object?> get props =>
      [rank, name, played, wins, draws, losses, goalsDifference, points];

  static PlayerStats get virtualStats => const PlayerStats(
      '#', "PLAYER", "P", "W", "D", "L", -10000, -10000, Colors.white);

  static PlayerStats fromModel(int index, PlayerStatsModel model) {
    return PlayerStats(
      (index + 1).toString(),
      model.playerModel.fullname,
      model.totalPlayed.toString(),
      model.wins.toString(),
      model.draws.toString(),
      model.losses.toString(),
      model.goalDifferent,
      model.points,
      randomObject(Colors.primaries),
    );
  }
}
