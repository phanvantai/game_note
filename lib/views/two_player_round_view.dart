import 'package:flutter/material.dart';
import 'package:game_note/model/two_player_round.dart';
import 'package:game_note/views/components/score_view.dart';
import 'package:game_note/views/components/submit_game_view.dart';

import 'add_player_view.dart';
import 'components/select_player_view.dart';

class TwoPlayerRoundView extends StatefulWidget {
  const TwoPlayerRoundView({Key? key}) : super(key: key);

  @override
  State<TwoPlayerRoundView> createState() => _TwoPlayerRoundViewState();
}

class _TwoPlayerRoundViewState extends State<TwoPlayerRoundView> {
  TwoPlayerRound? twoPlayerRound;
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: twoPlayerRound != null
                ? const Text("Two-Player-Round")
                : const Text("Select Players"),
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPlayerView(),
                    ),
                  );
                },
                icon: const Icon(Icons.person_add),
              )
            ],
          ),
          body: twoPlayerRound != null
              ? _twoPlayerRound()
              : SelectPlayerView(
                  2,
                  onSelectDone: (players) {
                    setState(() {
                      twoPlayerRound = TwoPlayerRound(
                          player1: players[0], player2: players[1]);
                    });
                  },
                ),
        ),
      ),
      onWillPop: () async {
        return true;
      },
    );
  }

  _twoPlayerRound() {
    if (twoPlayerRound == null) {
      return Container();
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ScoreView(twoPlayerRound: twoPlayerRound!),
            const Divider(
              height: 4,
              color: Colors.black,
            ),
            const Text("Recent Matchs"),
            Expanded(
              child: ListView.builder(
                itemCount: twoPlayerRound!.games.length,
                itemBuilder: (context, index) {
                  var game = twoPlayerRound!.games[index];
                  return Center(child: Text("${game.score1} - ${game.score2}"));
                },
              ),
            ),
            SubmitGameView(twoPlayerRound!.player1, twoPlayerRound!.player2,
                onSubmitGame: (game) {
              setState(() {
                twoPlayerRound?.games.insert(0, game);
              });
            })
          ],
        ),
      );
    }
  }
}
