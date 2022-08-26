import 'package:equatable/equatable.dart';

import 'club_model.dart';
import 'player_model.dart';

class ResultModel extends Equatable {
  final int? id;
  final int? score;
  final int matchId;
  final PlayerModel playerModel;
  final ClubModel? clubModel;

  const ResultModel({
    this.id,
    required this.matchId,
    this.score,
    required this.playerModel,
    this.clubModel,
  });

  ResultModel copyWith({
    int? id,
    int? score,
    int? matchId,
    PlayerModel? playerModel,
    ClubModel? clubModel,
  }) {
    return ResultModel(
      matchId: matchId ?? this.matchId,
      id: id ?? this.id,
      score: score ?? this.score,
      playerModel: playerModel ?? this.playerModel,
      clubModel: clubModel ?? this.clubModel,
    );
  }

  @override
  List<Object?> get props => [id, matchId, playerModel, score, clubModel];
}
