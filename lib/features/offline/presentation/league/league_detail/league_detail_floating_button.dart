import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/league_detail_bloc.dart';

class LeagueDetailFloatingButton extends StatelessWidget {
  const LeagueDetailFloatingButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeagueDetailBloc, LeagueDetailState>(
        builder: (context, state) {
      if (state.status.isEmpty) {
        return FloatingActionButton(
          onPressed: () {
            BlocProvider.of<LeagueDetailBloc>(context).add(AddPlayersStarted());
          },
          tooltip: 'Thêm người chơi',
          child: const Icon(Icons.add),
        );
      }
      if (state.status.isLoaded) {
        return FloatingActionButton(
          onPressed: () {
            BlocProvider.of<LeagueDetailBloc>(context).add(AddNewRounds());
          },
          tooltip: 'Thêm vòng đấu',
          child: const Icon(Icons.add),
        );
      }
      return const SizedBox.shrink();
    });
  }
}
