import 'package:game_note/model/player.dart';

import 'two_player_game.dart';

class TwoPlayerRound {
  final Player player1;
  final Player player2;
  List<TwoPlayerGame> games = [];

  TwoPlayerRound({
    required this.player1,
    required this.player2,
  });

  int countWin(Player player) {
    return games
        .map((e) => e.winner)
        .where((element) => element == player)
        .toList()
        .length;
  }
}
