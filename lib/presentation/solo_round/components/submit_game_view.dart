import 'package:flutter/material.dart';
import 'package:game_note/_old/model/two_player_game.dart';

import '../../../_old/model/player.dart';
import '../../../_old/views/components/player_view.dart';

class SubmitGameView extends StatefulWidget {
  final Player player1;
  final Player player2;
  final Function(TwoPlayerGame) onSubmitGame;
  const SubmitGameView(this.player1, this.player2,
      {Key? key, required this.onSubmitGame})
      : super(key: key);

  @override
  State<SubmitGameView> createState() => _SubmitGameViewState();
}

class _SubmitGameViewState extends State<SubmitGameView> {
  TextEditingController controller1 = TextEditingController();
  TextEditingController controller2 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _gameView(),
    );
  }

  List<Widget> _gameView() {
    return [
      Row(
        children: [
          const Spacer(),
          PlayerView(widget.player1, onClick: null),
          Expanded(
            child: TextField(
              cursorColor: Colors.white,
              controller: controller1,
              textAlign: TextAlign.right,
              keyboardType: TextInputType.number,
              maxLength: 2,
              onChanged: (value) {
                setState(() {
                  controller1 = controller1;
                });
              },
            ),
          ),
          const Text("   -   "),
          Expanded(
            child: TextField(
              cursorColor: Colors.white,
              controller: controller2,
              keyboardType: TextInputType.number,
              maxLength: 2,
              onChanged: (value) {
                setState(() {
                  controller2 = controller2;
                });
              },
            ),
          ),
          PlayerView(widget.player2, onClick: null),
          const Spacer(),
        ],
      ),
      ElevatedButton(
        onPressed: controller1.text.isEmpty || controller2.text.isEmpty
            ? null
            : () {
                var game = TwoPlayerGame(
                    player1: widget.player1, player2: widget.player2);
                game.score1 = int.parse(controller1.text);
                game.score2 = int.parse(controller2.text);
                widget.onSubmitGame(game);
                setState(() {
                  controller1.text = "";
                  controller2.text = "";
                });
              },
        child: const Text("Submit result"),
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all<Color>(
            controller1.text.isEmpty || controller2.text.isEmpty
                ? Colors.orange.withOpacity(0.5)
                : Colors.orange,
          ),
        ),
      ),
    ];
  }
}
