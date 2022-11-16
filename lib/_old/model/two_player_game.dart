import '../../features/offline/domain/entities/player_model.dart';

class TwoPlayerGame {
  final PlayerModel player1;
  final PlayerModel player2;
  int? score1;
  int? score2;
  String? photoUrl;
  int? id;

  TwoPlayerGame({
    required this.player1,
    required this.player2,
    this.score1,
    this.score2,
    this.photoUrl,
    this.id,
  });

  PlayerModel? get winner {
    PlayerModel? winner;
    if (score1 == null || score2 == null) {
      winner = null;
    } else {
      if (score1! > score2!) {
        winner = player1;
      } else if (score1 == score2) {
        winner = null;
      } else {
        winner = player2;
      }
    }
    return winner;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'player1': player1.id,
      'player2': player2.id,
      'score1': score1,
      'score2': score2,
      'photoUrl': photoUrl,
    };
  }

  @override
  String toString() {
    return 'Game{id: $id, player1: ${player1.fullname} $score1 - $score2 ${player2.fullname}}';
  }
}
