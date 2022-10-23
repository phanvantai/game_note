import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/league/league/bloc/league_detail_bloc.dart';
import 'package:game_note/presentation/league/league/bloc/league_detail_state.dart';
import 'package:game_note/presentation/league/league/components/table_item_view.dart';
import 'package:game_note/presentation/models/player_stats.dart';

class TableView extends StatelessWidget {
  const TableView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeagueDetailBloc, LeagueDetailState>(
      builder: (context, state) => Column(
        children: [
          TableItemView(model: PlayerStats.virtualStats),
          ...List.generate(
            state.model!.players.length,
            (index) => TableItemView(
              model: PlayerStats.fromModel(
                index,
                state.model!.players[index],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
