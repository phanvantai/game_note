import 'package:equatable/equatable.dart';

import 'club_model.dart';
import 'player_model.dart';

class ResultModel extends Equatable {
  final int? id;
  final int? score;
  final PlayerModel playerModel;
  final ClubModel? clubModel;

  const ResultModel({
    this.id,
    this.score,
    required this.playerModel,
    this.clubModel,
  });

  ResultModel copyWith({
    int? id,
    int? score,
    PlayerModel? playerModel,
    ClubModel? clubModel,
  }) {
    return ResultModel(
      id: id ?? this.id,
      score: score ?? this.score,
      playerModel: playerModel ?? this.playerModel,
    );
  }

  @override
  List<Object?> get props => [playerModel, score, clubModel];
}
