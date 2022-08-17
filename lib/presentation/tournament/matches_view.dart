import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_state.dart';
import 'package:game_note/presentation/tournament/list_matches_view.dart';

class MatchesView extends StatelessWidget {
  const MatchesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(child: Text('Fixtures')),
              Tab(icon: Text('Results')),
            ],
            indicatorColor: Colors.orange,
            indicatorWeight: 4,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<TournamentBloc, TournamentState>(
              builder: (context, state) => TabBarView(
                children: [
                  ListMatchesView(
                      list: state.matches
                          .where((element) => element.status == false)
                          .toList()),
                  ListMatchesView(
                      list: state.matches
                          .where((element) => element.status == true)
                          .toList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
