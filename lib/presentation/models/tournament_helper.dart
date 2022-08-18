import 'package:flutter/material.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/presentation/models/player_stats.dart';

class TournamentHelper {
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

  static PlayerStats getStats(PlayerModel player, List<MatchModel> matches) {
    var matchesPlayed = matches
        .where((element) =>
            element.status == true &&
            (element.home.playerModel == player ||
                element.away.playerModel == player))
        .toList();
    var wins = matchesPlayed
        .where((e) => ResultTypeX.result(player, e).isWin)
        .toList()
        .length;
    var draws = matchesPlayed
        .where((e) => ResultTypeX.result(player, e).isDraw)
        .toList()
        .length;
    var losses = matchesPlayed
        .where((e) => ResultTypeX.result(player, e).isLost)
        .toList()
        .length;
    return PlayerStats(
        0.toString(),
        player.fullname,
        matchesPlayed.length.toString(),
        wins.toString(),
        draws.toString(),
        losses.toString(),
        0.toString(),
        (wins * 3 + draws * 1).toString(),
        player.color ?? randomObject(Colors.primaries));
  }
}
