import 'package:flutter/material.dart';
import 'package:game_note/model/two_player_round.dart';

import '../../core/constants/constants.dart';
import 'player_view.dart';

class ScoreView extends StatelessWidget {
  final TwoPlayerRound twoPlayerRound;
  const ScoreView({Key? key, required this.twoPlayerRound}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PlayerView(
                twoPlayerRound.player1,
                onClick: null,
                bold: true,
              ),
              Text(
                twoPlayerRound.countWin(twoPlayerRound.player1).toString(),
                style: boldTextStyle,
              ),
            ],
          ),
        ),
        const Text("  -  "),
        Expanded(
            child: Row(
          children: [
            Text(
              twoPlayerRound.countWin(twoPlayerRound.player2).toString(),
              style: boldTextStyle,
            ),
            PlayerView(
              twoPlayerRound.player2,
              onClick: null,
              bold: true,
            ),
          ],
        )),
      ],
    );
  }
}
