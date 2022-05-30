import 'package:flutter/material.dart';
import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/model/two_player_round.dart';
import 'package:game_note/views/components/score_view.dart';
import 'package:game_note/views/components/submit_game_view.dart';

import '../components/select_player_view.dart';

class TwoPlayerRoundView extends StatefulWidget {
  final TwoPlayerRound? twoPlayerRound;
  const TwoPlayerRoundView({Key? key, this.twoPlayerRound}) : super(key: key);

  @override
  State<TwoPlayerRoundView> createState() => _TwoPlayerRoundViewState();
}

class _TwoPlayerRoundViewState extends State<TwoPlayerRoundView> {
  TwoPlayerRound? twoPlayerRound;
  @override
  void initState() {
    twoPlayerRound = widget.twoPlayerRound;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.twoPlayerRound != null) {
      return GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Scaffold(
          appBar: AppBar(
            title: twoPlayerRound != null
                ? Text(twoPlayerRound!.name ?? "Two-Player-Round")
                : const Text("Select Players"),
          ),
          body: twoPlayerRound != null
              ? _twoPlayerRound()
              : SelectPlayerView(
                  2,
                  onSelectDone: (players) async {
                    int id = await getIt<DatabaseManager>()
                        .insertTwoPlayerRound(TwoPlayerRound(
                            player1: players[0], player2: players[1]));
                    var round = await getIt<DatabaseManager>().round(id);
                    setState(() {
                      twoPlayerRound = round;
                    });
                  },
                ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: twoPlayerRound != null
          ? _twoPlayerRound()
          : SelectPlayerView(
              2,
              onSelectDone: (players) async {
                int id = await getIt<DatabaseManager>().insertTwoPlayerRound(
                    TwoPlayerRound(player1: players[0], player2: players[1]));
                var round = await getIt<DatabaseManager>().round(id);
                setState(() {
                  twoPlayerRound = round;
                });
              },
            ),
    );
  }

  _twoPlayerRound() {
    if (twoPlayerRound == null) {
      return Container();
    } else {
      var draw = twoPlayerRound!.games
          .where((element) => element.winner == null)
          .toList()
          .length;
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ScoreView(twoPlayerRound: twoPlayerRound!),
            const Divider(
              height: 4,
              color: Colors.black,
            ),
            Text("Total Games: ${twoPlayerRound!.games.length}"),
            Text("Draw: $draw"),
            Expanded(
              child: ListView.builder(
                itemCount: twoPlayerRound!.games.length,
                itemBuilder: (context, index) {
                  var game = twoPlayerRound!.games[index];
                  return Center(
                      child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text("${game.score1} - ${game.score2}")));
                },
              ),
            ),
            if (widget.twoPlayerRound == null)
              SubmitGameView(twoPlayerRound!.player1, twoPlayerRound!.player2,
                  onSubmitGame: (game) async {
                var id =
                    await getIt<DatabaseManager>().insertTwoPlayerGame(game);
                var g = await getIt<DatabaseManager>().game(id);

                if (g != null) {
                  setState(() {
                    twoPlayerRound?.games.insert(0, g);
                  });
                  await getIt<DatabaseManager>().updateRound(twoPlayerRound!);
                }
              })
          ],
        ),
      );
    }
  }
}
