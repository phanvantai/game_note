import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/league/league_list/bloc/league_list_bloc.dart';
import 'package:game_note/presentation/league/league_list/bloc/league_list_state.dart';

import 'add_tournament_button.dart';
import 'league_list_body.dart';

class LeagueListView extends StatelessWidget {
  const LeagueListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BlocBuilder<LeagueListBloc, LeagueListState>(
            builder: (context, state) {
          switch (state.status) {
            case LeagueListStatus.error:
              return const Center(child: Text('error'));
            case LeagueListStatus.loading:
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            case LeagueListStatus.loaded:
              if (state.leagues.isEmpty) {
                return const Center(
                  child: Text(
                    'No tournaments have been created yet. Click plus button below to create new one.',
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                );
              } else {
                return const LeagueListBody();
              }
          }
        }),
      ),
      floatingActionButton: const AddTournamentButton(),
    );
  }
}
