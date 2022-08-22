import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/leagues/bloc/league_list_bloc.dart';
import 'package:game_note/presentation/tournament/leagues/bloc/league_list_event.dart';
import 'package:game_note/presentation/tournament/leagues/bloc/league_list_state.dart';

class TournamentListView extends StatelessWidget {
  const TournamentListView({Key? key}) : super(key: key);

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
            return Text('list view');
          }),
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
