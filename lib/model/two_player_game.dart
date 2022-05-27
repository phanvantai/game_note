import 'package:game_note/model/player.dart';

class TwoPlayerGame {
  final Player player1;
  final Player player2;
  int? score1;
  int? score2;
  String? photoUrl;

  TwoPlayerGame({
    required this.player1,
    required this.player2,
  });

  Player? get winner {
    if (score1 == null || score2 == null) {
      return null;
    } else {
      if (score1! > score2!) {
        return player1;
      } else if (score1 == score2) {
        return null;
      } else {
        return player2;
      }
    }
  }
}
