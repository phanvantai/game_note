import 'package:equatable/equatable.dart';
import 'package:game_note/features/offline/data/database/database_manager.dart';
import 'package:game_note/features/offline/domain/entities/player_model.dart';
import 'package:game_note/features/offline/domain/entities/result_model.dart';

class MatchModel extends Equatable {
  final int? id;
  // status: finished: true, not finished: false
  final bool status;
  final int roundId;
  final ResultModel? home;
  final ResultModel? away;
  final String? created;

  const MatchModel({
    this.id,
    required this.roundId,
    this.home,
    this.away,
    this.status = false,
    this.created,
  });

  MatchModel copyWith({
    int? id,
    bool? status,
    int? roundId,
    ResultModel? home,
    ResultModel? away,
    String? created,
  }) {
    return MatchModel(
      id: id ?? this.id,
      roundId: roundId ?? this.roundId,
      home: home ?? this.home,
      away: away ?? this.away,
      status: status ?? this.status,
      created: created ?? this.created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      DBTableColumn.matchId: id,
      DBTableColumn.roundId: roundId,
      DBTableColumn.matchStatus: status ? 1 : 0,
      DBTableColumn.datetime: created,
    };
  }

  @override
  List<Object?> get props => [
        id,
        status,
        roundId,
        home,
        away,
      ];
}

enum ResultType { win, draw, lost, unknown }

extension ResultTypeX on ResultType {
  bool get isWin => this == ResultType.win;
  bool get isDraw => this == ResultType.draw;
  bool get isLost => this == ResultType.lost;
  bool get isUnknown => this == ResultType.unknown;

  static ResultType result(PlayerModel player, MatchModel match) {
    if (match.status == false ||
        (match.home?.playerModel != player &&
            match.away?.playerModel != player) ||
        match.home?.score == null ||
        match.away?.score == null) {
      return ResultType.unknown;
    }
    if (match.home?.score == match.away?.score) {
      return ResultType.draw;
    }
    if (match.home!.score! > match.away!.score!) {
      return match.home?.playerModel == player
          ? ResultType.win
          : ResultType.lost;
    } else {
      return match.home?.playerModel == player
          ? ResultType.lost
          : ResultType.win;
    }
  }
}

extension MatchModelX on MatchModel {
  // static List<MatchModel> from(List<Map<PlayerModel, PlayerModel>> map) {
  //   List<MatchModel> matches = [];
  //   for (var element in map) {
  //     matches.add(MatchModel(
  //       home: ResultModel(playerModel: element.entries.first.key, matchId: 1),
  //       away: ResultModel(playerModel: element.entries.first.value, matchId: 1),
  //     ));
  //   }
  //   return matches;
  // }
}
