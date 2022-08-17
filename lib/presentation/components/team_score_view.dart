import 'package:flutter/material.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/_old/model/two_player_round.dart';

class TeamScoreView extends StatelessWidget {
  final TwoPlayerRound round;
  final PlayerModel player;
  const TeamScoreView({
    Key? key,
    required this.player,
    required this.round,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: player.color,
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            player.fullname,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            round.countWin(player).toString(),
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
