import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/components/table_item_view.dart';
import 'package:game_note/presentation/models/player_stats.dart';
import 'package:game_note/presentation/models/tournament_helper.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_state.dart';

class TableView extends StatelessWidget {
  const TableView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentBloc, TournamentState>(
      builder: (context, state) => Column(
        children: [
          TableItemView(model: PlayerStats.virtualStats),
          ...TournamentHelper.createTable(state.players, state.matches)
              .map((e) => TableItemView(model: e))
              .toList(),
        ],
      ),
    );
  }
}
