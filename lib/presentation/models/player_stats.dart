import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class PlayerStats extends Equatable {
  final String rank;
  final String name;
  final String played;
  final String wins;
  final String draws;
  final String losses;
  final String goalsDifference;
  final String points;
  final Color color;

  const PlayerStats(this.rank, this.name, this.played, this.wins, this.draws,
      this.losses, this.goalsDifference, this.points, this.color);

  @override
  List<Object?> get props =>
      [rank, name, played, wins, draws, losses, goalsDifference, points];

  static PlayerStats get virtualStats => const PlayerStats(
      '#', "PLAYER", "P", "W", "D", "L", "GD", "PTS", Colors.white);
}
