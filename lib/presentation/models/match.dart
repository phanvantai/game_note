import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/domain/entities/result_model.dart';

class Match {
  final MatchModel matchModel;
  static List<Match> dump = [
    Match(MatchModel(
      home: const ResultModel(
        playerModel: PlayerModel(fullname: 'test 1'),
        score: 0,
      ),
      away: const ResultModel(
        playerModel: PlayerModel(fullname: 'test 2'),
        score: 1,
      ),
    )),
    Match(MatchModel(
      home: const ResultModel(
        playerModel: PlayerModel(fullname: 'test 1'),
        score: 0,
      ),
      away: const ResultModel(
        playerModel: PlayerModel(fullname: 'test 2'),
        score: 1,
      ),
    )),
    Match(MatchModel(
      home: const ResultModel(
        playerModel: PlayerModel(fullname: 'test 1'),
        score: 0,
      ),
      away: const ResultModel(
        playerModel: PlayerModel(fullname: 'test 2'),
        score: 1,
      ),
    )),
    Match(MatchModel(
      home: const ResultModel(
        playerModel: PlayerModel(fullname: 'test 1'),
        score: 0,
      ),
      away: const ResultModel(
        playerModel: PlayerModel(fullname: 'test 2'),
        score: 1,
      ),
    )),
  ];

  Match(this.matchModel);
}
