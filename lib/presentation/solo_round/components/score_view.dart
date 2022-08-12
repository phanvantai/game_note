import 'package:flutter/material.dart';
import 'package:game_note/_old/model/two_player_round.dart';
import 'package:game_note/core/constants/constants.dart';
import '../../../_old/views/components/player_view.dart';

class ScoreView extends StatelessWidget {
  final TwoPlayerRound twoPlayerRound;
  const ScoreView({Key? key, required this.twoPlayerRound}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _playerView(
              twoPlayerRound.player1.fullname, twoPlayerRound.player1Score),
          _playerView(
              twoPlayerRound.player2.fullname, twoPlayerRound.player2Score),
        ],
      ),
    );
  }

  _playerView(String name, int score) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          ClipRRect(
            child: Container(
              decoration: BoxDecoration(
                color: randomObject(Colors.primaries),
                borderRadius: BorderRadius.circular(12),
              ),
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            score.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
