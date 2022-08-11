import 'package:flutter/material.dart';
import 'package:game_note/presentation/random_view.dart';
import 'package:game_note/presentation/solo_round/two_player_round_view.dart';

class RoundView extends StatefulWidget {
  const RoundView({Key? key}) : super(key: key);

  @override
  State<RoundView> createState() => _RoundViewState();
}

class _RoundViewState extends State<RoundView> {
  List<Widget> listTabs = [
    const TwoPlayerRoundView(),
    const RandomView(),
  ];
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: listTabs.length,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text("NewRound"),
          bottom: const TabBar(tabs: [
            Tab(
              text: "Round",
            ),
            Tab(
              text: "Random Wheel",
            )
          ]),
          backgroundColor: Colors.black,
        ),
        body: TabBarView(children: listTabs),
      ),
    );
  }
}
