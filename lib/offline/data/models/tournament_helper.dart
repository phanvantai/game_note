import 'package:game_note/core/ultils.dart';
import 'package:game_note/offline/domain/entities/match_model.dart';
import 'package:game_note/offline/domain/entities/player_model.dart';
import 'package:game_note/offline/domain/entities/player_stats_model.dart';

class TournamentHelper {
  static List<List<Map<T, T>>> createRounds<T>(List<T> players, T virtual) {
    List<List<Map<T, T>>> listRounds = [];
    // n is odd, add a virtual player
    if (players.length % 2 != 0) {
      players.add(virtual);
    }

    // create first round matches
    listRounds.add(createMaps(players)
        .where((element) =>
            element.keys.first != virtual && element.values.first != virtual)
        .toList());
    // // rotate n-2 times
    for (int i = 0; i < players.length - 2; i++) {
      // rotate list
      players = rotateList(players);
      // create matches
      listRounds.add(createMaps(players)
          .where((element) =>
              element.keys.first != virtual && element.values.first != virtual)
          .toList());
    }
    // remove virtual player
    players.remove(virtual);
    return listRounds;
  }

  static List<Map<T, T>> createMatches<T>(List<T> players, T virtual) {
    List<Map<T, T>> matches = [];
    // n is odd, add a virtual player
    if (players.length % 2 != 0) {
      players.add(virtual);
    }
    // create first round matches
    matches.addAll(createMaps(players));
    // // rotate n-2 times
    for (int i = 0; i < players.length - 2; i++) {
      // rotate list
      players = rotateList(players);
      // create matches
      matches.addAll(createMaps(players));
    }
    // remove virtual player
    players.remove(virtual);
    // remove matches have virtual player
    return matches
        .where((element) =>
            element.keys.first != virtual && element.values.first != virtual)
        .toList();
  }

  static PlayerStatsModel updateStats(
      PlayerStatsModel statsModel, MatchModel matchModel) {
    var player = statsModel.playerModel;
    var result = ResultTypeX.result(player, matchModel);
    return PlayerStatsModel(
      id: statsModel.id,
      playerModel: player,
      leagueId: statsModel.leagueId,
      totalPlayed: statsModel.totalPlayed + 1,
      wins: result.isWin ? statsModel.wins + 1 : statsModel.wins,
      draws: result.isDraw ? statsModel.draws + 1 : statsModel.draws,
      losses: result.isLost ? statsModel.losses + 1 : statsModel.losses,
      goalDifferent:
          statsModel.goalDifferent + goalDifference(player, matchModel),
      points: result.isWin
          ? statsModel.points + 3
          : result.isDraw
              ? statsModel.points + 1
              : statsModel.points,
    );
  }

  static int goalDifference(PlayerModel player, MatchModel match) {
    if (match.status == false ||
        (match.home!.playerModel != player &&
            match.away!.playerModel != player) ||
        match.home!.score == null ||
        match.away!.score == null) {
      return 0;
    }
    return player == match.home!.playerModel
        ? match.home!.score! - match.away!.score!
        : match.away!.score! - match.home!.score!;
  }
}
