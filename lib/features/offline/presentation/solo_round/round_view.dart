import 'package:flutter/material.dart';
import 'package:game_note/features/offline/presentation/solo_round/two_player_round_view.dart';

class RoundView extends StatelessWidget {
  const RoundView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black),
      backgroundColor: Colors.black,
      body: const SafeArea(
        child: TwoPlayerRoundView(),
      ),
    );
  }
}
