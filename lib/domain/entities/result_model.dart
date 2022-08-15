import 'package:equatable/equatable.dart';

import 'club_model.dart';
import 'player_model.dart';

class ResultModel extends Equatable {
  // status: finished: true, not finished: false
  final bool status;
  final int? score;
  final PlayerModel playerModel;
  final ClubModel? clubModel;

  const ResultModel({
    this.status = false,
    this.score,
    required this.playerModel,
    this.clubModel,
  });
  @override
  List<Object?> get props => [playerModel, score, clubModel, status];
}
