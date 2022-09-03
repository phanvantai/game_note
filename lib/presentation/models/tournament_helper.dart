import 'package:game_note/core/ultils.dart';

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

  // static List<PlayerStats> createTable(
  //     List<PlayerModel> players, List<MatchModel> matches) {
  //   var list =
  //       players.map((e) => TournamentHelper.getStats(e, matches)).toList();
  //   list.sort((a, b) {
  //     if (a.points > b.points) {
  //       return -1;
  //     } else if (a.points < b.points) {
  //       return 1;
  //     } else {
  //       if (a.goalsDifference > b.goalsDifference) {
  //         return -1;
  //       } else if (a.goalsDifference < b.goalsDifference) {
  //         return 1;
  //       } else {
  //         return 0;
  //       }
  //     }
  //   });
  //   return list;
  // }

  // static int goalDifference(PlayerModel player, MatchModel match) {
  //   if (match.status == false ||
  //       (match.home.playerModel != player &&
  //           match.away.playerModel != player) ||
  //       match.home.score == null ||
  //       match.away.score == null) {
  //     return 0;
  //   }
  //   return player == match.home.playerModel
  //       ? match.home.score! - match.away.score!
  //       : match.away.score! - match.home.score!;
  // }

  // static PlayerStats getStats(PlayerModel player, List<MatchModel> matches) {
  //   var matchesPlayed = matches
  //       .where((element) =>
  //           element.status == true &&
  //           (element.home.playerModel == player ||
  //               element.away.playerModel == player))
  //       .toList();
  //   var wins = matchesPlayed
  //       .where((e) => ResultTypeX.result(player, e).isWin)
  //       .toList()
  //       .length;
  //   var draws = matchesPlayed
  //       .where((e) => ResultTypeX.result(player, e).isDraw)
  //       .toList()
  //       .length;
  //   var losses = matchesPlayed
  //       .where((e) => ResultTypeX.result(player, e).isLost)
  //       .toList()
  //       .length;
  //   int gd = 0;
  //   for (var match in matchesPlayed) {
  //     gd += goalDifference(player, match);
  //   }
  //   return PlayerStats(
  //       0.toString(),
  //       player.fullname,
  //       matchesPlayed.length.toString(),
  //       wins.toString(),
  //       draws.toString(),
  //       losses.toString(),
  //       gd,
  //       wins * 3 + draws * 1,
  //       player.color ?? randomObject(Colors.primaries));
  // }
}
