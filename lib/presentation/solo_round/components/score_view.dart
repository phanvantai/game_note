import 'package:flutter/material.dart';
import 'package:game_note/_old/model/two_player_round.dart';
import 'package:game_note/presentation/solo_round/components/player_item_view.dart';

class ScoreView extends StatelessWidget {
  final TwoPlayerRound twoPlayerRound;
  const ScoreView({Key? key, required this.twoPlayerRound}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          PlayerItemView(
              text: twoPlayerRound.player1.fullname,
              score: twoPlayerRound.player1Score),
          PlayerItemView(
              text: twoPlayerRound.player2.fullname,
              score: twoPlayerRound.player2Score),
        ],
      ),
    );
  }
}
