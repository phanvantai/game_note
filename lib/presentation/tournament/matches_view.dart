import 'package:flutter/material.dart';
import 'package:game_note/presentation/tournament/list_matches_view.dart';

class MatchesView extends StatelessWidget {
  const MatchesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: const [
          TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(child: Text('Fixtures')),
              Tab(icon: Text('Results')),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                ListMatchesView(),
                ListMatchesView(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
