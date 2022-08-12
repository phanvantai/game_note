import 'package:flutter/material.dart';
import 'package:game_note/presentation/tournament/matches_view.dart';
import 'package:game_note/presentation/tournament/table_view.dart';

class TournamentView extends StatelessWidget {
  const TournamentView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: const [
              TabBar(
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  Tab(child: Text('Table')),
                  Tab(icon: Text('Matches')),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    TableView(),
                    MatchesView(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
