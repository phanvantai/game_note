import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:game_note/features/offline/domain/entities/player_stats_model.dart';

class PlayerStats extends Equatable {
  final String rank;
  final String name;
  final String played;
  final String wins;
  final String draws;
  final String losses;
  final int goalsDifference;
  final int points;
  final Color? color;

  const PlayerStats({
    required this.rank,
    required this.name,
    required this.played,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.goalsDifference,
    required this.points,
    this.color,
  });

  @override
  List<Object?> get props =>
      [rank, name, played, wins, draws, losses, goalsDifference, points];

  static PlayerStats get virtualStats => const PlayerStats(
        rank: '#',
        name: "PLAYER",
        played: "P",
        wins: "W",
        draws: "D",
        losses: "L",
        goalsDifference: -10000,
        points: -10000,
      );

  static PlayerStats fromModel(int index, PlayerStatsModel model) {
    return PlayerStats(
      rank: (index + 1).toString(),
      name: model.playerModel.fullname,
      played: model.totalPlayed.toString(),
      wins: model.wins.toString(),
      draws: model.draws.toString(),
      losses: model.losses.toString(),
      goalsDifference: model.goalDifferent,
      points: model.points,
      //randomObject(Colors.primaries),
    );
  }
}
