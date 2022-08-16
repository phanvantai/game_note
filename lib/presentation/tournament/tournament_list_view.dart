import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/matches_view.dart';
import 'package:game_note/presentation/tournament/table_view.dart';

class TournamentListView extends StatelessWidget {
  const TournamentListView({Key? key}) : super(key: key);

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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          BlocProvider.of<TournamentBloc>(context).add(AddNewTournamentEvent());
        },
        tooltip: 'Add New Tournament',
        child: const Icon(Icons.add),
      ),
    );
  }
}
