import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/tournament_bloc.dart';
import 'components/add_league_dialog.dart';

class AddTournamentButton extends StatelessWidget {
  const AddTournamentButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (buildContext) => AddLeagueDialog(callback: (name) {
            BlocProvider.of<TournamentBloc>(context)
                .add(AddNewLeagueEvent(name));
          }),
        );
      },
      tooltip: 'Thêm giải đấu mới',
      child: const Icon(Icons.add),
    );
  }
}
