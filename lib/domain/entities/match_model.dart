import 'package:equatable/equatable.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/domain/entities/result_model.dart';

class MatchModel extends Equatable {
  // status: finished: true, not finished: false
  final bool status;
  final ResultModel home;
  final ResultModel away;
  final DateTime created = DateTime.now();

  MatchModel({required this.home, required this.away, this.status = false});

  @override
  List<Object?> get props => [home, away, created, status];
}

enum ResultType { win, draw, lost, unknown }

extension ResultTypeX on ResultType {
  bool get isWin => this == ResultType.win;
  bool get isDraw => this == ResultType.draw;
  bool get isLost => this == ResultType.lost;
  bool get isUnknown => this == ResultType.unknown;

  static ResultType result(PlayerModel player, MatchModel match) {
    if (match.status == false ||
        (match.home.playerModel != player &&
            match.away.playerModel != player) ||
        match.home.score == null ||
        match.away.score == null) {
      return ResultType.unknown;
    }
    if (match.home.score == match.away.score) {
      return ResultType.draw;
    }
    if (match.home.score! > match.away.score!) {
      return match.home.playerModel == player
          ? ResultType.win
          : ResultType.lost;
    } else {
      return match.home.playerModel == player
          ? ResultType.lost
          : ResultType.win;
    }
  }
}

extension MatchModelX on MatchModel {
  static List<MatchModel> from(List<Map<PlayerModel, PlayerModel>> map) {
    List<MatchModel> matches = [];
    for (var element in map) {
      matches.add(MatchModel(
        home: ResultModel(playerModel: element.entries.first.key),
        away: ResultModel(playerModel: element.entries.first.value),
      ));
    }
    return matches;
  }
}
