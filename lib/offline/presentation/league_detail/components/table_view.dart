import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/offline/presentation/models/player_stats.dart';

import '../bloc/league_detail_bloc.dart';
import 'table_item_view.dart';

class TableView extends StatelessWidget {
  const TableView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<LeagueDetailBloc, LeagueDetailState>(
      builder: (context, state) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            TableItemView(
              model: PlayerStats.virtualStats,
              isHeader: true,
            ),
            ...List.generate(
              state.model!.players.length,
              (index) => TableItemView(
                model: PlayerStats.fromModel(
                  index,
                  state.model!.players[index],
                ),
                isEven: index % 2 == 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
