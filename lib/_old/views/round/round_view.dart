import 'package:flutter/material.dart';
import 'package:game_note/_old/views/round/two_player_round_view.dart';

import '../add_player_view.dart';
import 'random_view.dart';

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
          actions: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddPlayerView()),
                );
              },
              icon: const Icon(Icons.person_add),
            )
          ],
        ),
        body: TabBarView(children: listTabs),
      ),
    );
  }
}
