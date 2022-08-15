import '../../domain/entities/player_model.dart';
import 'two_player_game.dart';

class TwoPlayerRound {
  final PlayerModel player1;
  final PlayerModel player2;
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

  int countWin(PlayerModel player) {
    return games
        .map((e) => e.winner)
        .where((element) => element?.id == player.id)
        .toList()
        .length;
  }

  String getName() {
    var date = DateTime.now();
    return '${date.day}-${date.month}-${date.year}';
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
