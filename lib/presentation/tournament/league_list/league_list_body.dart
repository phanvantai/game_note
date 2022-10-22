import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/tournament_bloc.dart';
import '../bloc/tournament_event.dart';
import 'bloc/league_list_bloc.dart';
import 'bloc/league_list_state.dart';

class LeagueListBody extends StatelessWidget {
  const LeagueListBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeagueListBloc, LeagueListState>(
      builder: (context, state) => Column(
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
                margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
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
      ),
    );
  }
}
