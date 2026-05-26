import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/l10n/l10n.dart';

import 'bloc/league_list_bloc.dart';
import 'components/add_league_dialog.dart';

class AddTournamentButton extends StatelessWidget {
  const AddTournamentButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'add_league',
      onPressed: () {
        showDialog(
          context: context,
          builder: (buildContext) => AddLeagueDialog(
            callback: (name) {
              context.read<LeagueListBloc>().add(CreateLeagueEvent(name));
            },
          ),
        );
      },
      tooltip: context.l10n.offlineAddLeagueTooltip,
      child: const Icon(Icons.add),
    );
  }
}
