import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/league_list/add_league_dialog.dart';
import 'package:game_note/presentation/tournament/league_list/bloc/league_list_bloc.dart';
import 'package:game_note/presentation/tournament/league_list/bloc/league_list_event.dart';
import 'package:game_note/presentation/tournament/league_list/bloc/league_list_state.dart';

class LeagueListView extends StatelessWidget {
  const LeagueListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BlocProvider(
          create: (_) =>
              LeagueListBloc(getLeagues: getIt())..add(LeagueListStarted()),
          child: BlocBuilder<LeagueListBloc, LeagueListState>(
              builder: (context, state) {
            if (state.status.isError) {
              return const Center(child: Text('error'));
            }
            if (state.status.isLoading) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.white));
            }
            if (state.leagues.isEmpty) {
              return const Center(
                child: Text(
                  'No tournaments have been created yet. Click plus button below to create new one.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text("List league"),
                ),
                for (var league in state.leagues)
                  GestureDetector(
                    onTap: () => BlocProvider.of<TournamentBloc>(context)
                        .add(SelectLeagueEvent(league)),
                    child: Container(
                      color: Colors.grey.withOpacity(0.3),
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(
                          bottom: 16, left: 16, right: 16),
                      child: Center(
                        child: Text(
                          league.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (buildContext) => AddLeagueDialog(callback: (name) {
              BlocProvider.of<TournamentBloc>(context)
                  .add(AddNewLeagueEvent(name));
            }),
          );
        },
        tooltip: 'Add New Tournament',
        child: const Icon(Icons.add),
      ),
    );
  }
}
