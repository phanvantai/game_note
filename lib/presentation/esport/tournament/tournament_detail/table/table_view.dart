import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:pes_arena/widgets/gn_circle_avatar.dart';

import '../../../../../firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import '../../cost/cost_summary_panel.dart';
import 'widgets/table_fixed_column_header.dart';
import 'widgets/table_scrollable_column_header.dart';
import 'widgets/table_scrollable_column_item.dart';

class EsportTableView extends StatelessWidget {
  const EsportTableView({super.key});

  static const double tableRowHeight = 44.0;
  static const double tableIconColumnWidth = 44.0;
  static const double tableNameColumnWidth = 120.0;
  static const double tableStatsColumnWidth = 36.0;

  BoxDecoration tableItemDecor(BuildContext context, {bool isEven = false}) =>
      BoxDecoration(
        color: isEven
            ? Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
      );

  BoxDecoration tableHeaderDecor(BuildContext context) => BoxDecoration(
    color: Theme.of(context).colorScheme.surfaceContainerHighest,
    border: Border(
      bottom: BorderSide(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        width: 1,
      ),
    ),
  );

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<TournamentDetailBloc>();
    final leagueId = bloc.state.league?.id;
    if (leagueId == null) return;
    final tickBefore = bloc.state.refreshTick;
    bloc.add(GetParticipantsAndMatches(leagueId));
    // Wait until the bloc bumps the refresh tick. We can't watch viewStatus
    // because reactive refreshes don't toggle it, and we can't watch list
    // contents because Equatable suppresses emits when nothing changed.
    await bloc.stream.firstWhere((s) => s.refreshTick > tickBefore);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentDetailBloc, TournamentDetailState>(
      builder: (context, state) {
        final league = state.league;
        return RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: state.participants.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(
                      height: 400,
                      child: AppEmptyState(
                        icon: Icons.people_outline,
                        title: 'Chưa có người chơi nào',
                        subtitle: 'Thêm người chơi để bắt đầu giải đấu',
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _buildFixColumns(context, state.participants),
                          ),
                          Flexible(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              physics: const ClampingScrollPhysics(),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _buildScrollableColumns(
                                  context,
                                  state.participants,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (league != null)
                        CostSummaryPanel(
                          league: league,
                          sortedStats: state.participants,
                          matches: state.matches,
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  List<Widget> _buildFixColumns(
    BuildContext context,
    List<GNEsportLeagueStat> listStats,
  ) {
    final textTheme = Theme.of(context).textTheme;
    return List.generate(listStats.length + 1, (index) {
      if (index == 0) {
        return TableFixedColumnHeader(
          tableIconColumnWidth: tableIconColumnWidth,
          tableRowHeight: tableRowHeight,
          decoration: tableHeaderDecor(context),
        );
      }
      final stats = listStats[index - 1];
      final isEven = index % 2 == 0;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: tableItemDecor(context, isEven: isEven),
            alignment: Alignment.center,
            width: tableIconColumnWidth - 4,
            height: tableRowHeight,
            child: index == 1
                ? SvgPicture.asset(
                    'assets/svg/award-solid.svg',
                    width: 16,
                    height: 16,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).colorScheme.error,
                      BlendMode.srcIn,
                    ),
                  )
                : Text('$index', style: textTheme.bodySmall),
          ),
          Container(
            alignment: Alignment.center,
            width: tableIconColumnWidth + 4,
            height: tableRowHeight,
            decoration: tableItemDecor(context, isEven: isEven),
            child: GNCircleAvatar(size: 32, photoUrl: stats.user?.photoUrl),
          ),
        ],
      );
    });
  }

  List<Widget> _buildScrollableColumns(
    BuildContext context,
    List<GNEsportLeagueStat> listStats,
  ) {
    return List.generate(listStats.length + 1, (index) {
      if (index == 0) {
        return TableScrollableColumnHeader(
          tableHeaderDecor: tableHeaderDecor(context),
          tableRowHeight: tableRowHeight,
          tableNameColumnWidth: tableNameColumnWidth,
          tableStatsColumnWidth: tableStatsColumnWidth,
        );
      }
      final stats = listStats[index - 1];
      final isEven = index % 2 == 0;
      return TableScrollableColumnItem(
        tableItemDecor: tableItemDecor(context, isEven: isEven),
        tableRowHeight: tableRowHeight,
        tableNameColumnWidth: tableNameColumnWidth,
        stats: stats,
        tableStatsColumnWidth: tableStatsColumnWidth,
      );
    });
  }
}
