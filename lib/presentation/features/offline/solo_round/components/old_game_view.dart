import 'package:flutter/material.dart';
import 'package:game_note/_old/model/two_player_game.dart';
import 'package:game_note/presentation/features/offline/solo_round/components/player_item_view.dart';

class OldGameView extends StatelessWidget {
  final TwoPlayerGame game;
  const OldGameView({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 32),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          PlayerItemView(
            text: game.player1.fullname,
            score: game.score1 ?? 0,
            ingame: true,
          ),
          PlayerItemView(
            text: game.player2.fullname,
            score: game.score2 ?? 0,
            ingame: true,
          ),
        ],
      ),
    );
  }
}
