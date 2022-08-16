import 'package:equatable/equatable.dart';

import 'club_model.dart';
import 'player_model.dart';

class ResultModel extends Equatable {
  final int? score;
  final PlayerModel playerModel;
  final ClubModel? clubModel;

  const ResultModel({
    this.score,
    required this.playerModel,
    this.clubModel,
  });
  @override
  List<Object?> get props => [playerModel, score, clubModel];
}
