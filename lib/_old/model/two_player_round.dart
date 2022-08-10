import 'player.dart';
import 'two_player_game.dart';

class TwoPlayerRound {
  final Player player1;
  final Player player2;
  List<TwoPlayerGame> games = [];
  int? id;
  String? name;

  TwoPlayerRound({
    required this.player1,
    required this.player2,
    this.id,
  }) {
    name = getName();
  }

  int get player1Score => countWin(player1);
  int get player2Score => countWin(player2);

  int countWin(Player player) {
    return games
        .map((e) => e.winner)
        .where((element) => element?.id == player.id)
        .toList()
        .length;
  }

  String getName() {
    var date = DateTime.now();
    return '${date.day}-${date.month}-${date.year}-${player1.fullname}-${player2.fullname}';
  }

  Map<String, dynamic> toMap() {
    var stringGame = "";
    for (var game in games) {
      stringGame += game.id!.toString();
      stringGame += ",";
    }
    return {
      'id': id,
      'player1': player1.id,
      'player2': player2.id,
      'games': stringGame,
      'name': name,
    };
  }

  @override
  String toString() {
    return 'Round{id: $id, $name}';
  }
}
