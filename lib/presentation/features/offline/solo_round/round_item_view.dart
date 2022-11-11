import 'package:flutter/material.dart';
import 'package:game_note/_old/model/two_player_round.dart';
import 'package:game_note/presentation/components/team_score_view.dart';

class RoundItemView extends StatelessWidget {
  final TwoPlayerRound model;
  const RoundItemView({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(model.name ?? ''),
          TeamScoreView(
            round: model,
            player: model.player1,
          ),
          TeamScoreView(
            round: model,
            player: model.player2,
          ),
        ],
      ),
    );
  }
}
