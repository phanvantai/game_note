import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/player_model.dart';

import 'club_model.dart';

class ResultModel extends Equatable {
  final int score;
  final PlayerModel playerModel;
  final ClubModel? clubModel;

  const ResultModel({
    required this.score,
    required this.playerModel,
    this.clubModel,
  });
  @override
  List<Object?> get props => [playerModel, score, clubModel];
}
