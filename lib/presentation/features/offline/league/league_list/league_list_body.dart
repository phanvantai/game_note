import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/tournament_bloc.dart';
import 'bloc/league_list_bloc.dart';

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
          Expanded(
            child: ListView.builder(
              itemCount: state.leagues.length,
              itemBuilder: (context, index) => GestureDetector(
                onTap: () => BlocProvider.of<TournamentBloc>(context)
                    .add(SelectLeagueEvent(state.leagues[index])),
                child: Container(
                  color: Colors.grey.withOpacity(0.3),
                  padding: const EdgeInsets.all(16),
                  margin:
                      const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                  child: Center(
                    child: Text(
                      state.leagues[index].name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
