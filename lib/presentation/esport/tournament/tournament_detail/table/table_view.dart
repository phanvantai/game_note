import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:pes_arena/widgets/gn_circle_avatar.dart';

import '../../../../../firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'widgets/table_fixed_column_header.dart';
import 'widgets/table_scrollable_column_header.dart';
import 'widgets/table_scrollable_column_item.dart';

class EsportTableView extends StatelessWidget {
  const EsportTableView({super.key});

  static const double tableRowHeight = 52.0;
  static const double tableIconColumnWidth = 44.0;
  static const double tableNameColumnWidth = 126.0;
  static const double tableStatsColumnWidth = 36.0;

  static const _gold = Color(0xFFFBBF24);
  static const _silver = Color(0xFF9CA3AF);
  static const _bronze = Color(0xFFCD853F);

  Color? _rankAccent(int rank) => switch (rank) {
        1 => _gold,
        2 => _silver,
        3 => _bronze,
        _ => null,
      };

  BoxDecoration tableItemDecor(BuildContext context, {required int rank}) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _rankAccent(rank);
    return BoxDecoration(
      color: accent != null
          ? accent.withValues(alpha: 0.08)
          : rank % 2 == 0
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
              : Colors.transparent,
      border: Border(
        bottom: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
    );
  }

  BoxDecoration tableRankCellDecor(BuildContext context, {required int rank}) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = _rankAccent(rank);
    return BoxDecoration(
      color: accent != null
          ? accent.withValues(alpha: 0.13)
          : rank % 2 == 0
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)
              : Colors.transparent,
      border: Border(
        bottom: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.12),
          width: 0.5,
        ),
        left: accent != null
            ? BorderSide(color: accent, width: 3)
            : BorderSide.none,
      ),
    );
  }

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
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withValues(alpha: 0.28),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).colorScheme.shadow.withValues(alpha: 0.05),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _buildFixColumns(
                                context,
                                state.participants,
                              ),
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
                      ),
                      if (league != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _LeagueMetricSummary(
                            league: league,
                            participantCount: state.participants.length,
                            matchCount: state.matches.length,
                          ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return List.generate(listStats.length + 1, (index) {
      if (index == 0) {
        return TableFixedColumnHeader(
          tableIconColumnWidth: tableIconColumnWidth,
          tableRowHeight: tableRowHeight,
          decoration: tableHeaderDecor(context),
        );
      }
      final rank = index;
      final stats = listStats[rank - 1];
      final accent = _rankAccent(rank);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: tableRankCellDecor(context, rank: rank),
            alignment: Alignment.center,
            width: tableIconColumnWidth - 4,
            height: tableRowHeight,
            child: _RankBadge(rank: rank, accent: accent, colorScheme: colorScheme),
          ),
          Container(
            alignment: Alignment.center,
            width: tableIconColumnWidth + 4,
            height: tableRowHeight,
            decoration: tableItemDecor(context, rank: rank),
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
      final rank = index;
      final stats = listStats[rank - 1];
      return TableScrollableColumnItem(
        tableItemDecor: tableItemDecor(context, rank: rank),
        tableRowHeight: tableRowHeight,
        tableNameColumnWidth: tableNameColumnWidth,
        stats: stats,
        tableStatsColumnWidth: tableStatsColumnWidth,
        rank: rank,
      );
    });
  }
}

class _RankBadge extends StatelessWidget {
  final int rank;
  final Color? accent;
  final ColorScheme colorScheme;

  const _RankBadge({
    required this.rank,
    required this.accent,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (rank == 1) {
      return SvgPicture.asset(
        'assets/svg/award-solid.svg',
        width: 18,
        height: 18,
        colorFilter: const ColorFilter.mode(
          Color(0xFFFBBF24),
          BlendMode.srcIn,
        ),
      );
    }

    if (rank <= 3) {
      return Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: accent!.withValues(alpha: 0.2),
          shape: BoxShape.circle,
          border: Border.all(color: accent!, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          '$rank',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: accent,
            height: 1,
          ),
        ),
      );
    }

    return Text(
      '$rank',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }
}

class _LeagueMetricSummary extends StatelessWidget {
  final GNEsportLeague league;
  final int participantCount;
  final int matchCount;

  const _LeagueMetricSummary({
    required this.league,
    required this.participantCount,
    required this.matchCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final status = GNEsportLeagueStatusExtension.fromString(league.status);
    final dateRange = league.endDate == null
        ? DateFormat('dd/MM/yyyy').format(league.startDate)
        : '${DateFormat('dd/MM').format(league.startDate)} – ${DateFormat('dd/MM/yyyy').format(league.endDate!)}';
    final groupName = league.group?.groupName ?? 'Chưa rõ nhóm';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _StatCell(
                    value: '$participantCount',
                    label: 'Người chơi',
                    icon: Icons.people_alt_outlined,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colorScheme.outline.withValues(alpha: 0.18),
                ),
                Expanded(
                  child: _StatCell(
                    value: '$matchCount',
                    label: 'Trận đấu',
                    icon: Icons.sports_soccer_outlined,
                  ),
                ),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: colorScheme.outline.withValues(alpha: 0.18),
                ),
                Expanded(
                  child: _StatCell(
                    value: status.name,
                    label: 'Trạng thái',
                    icon: Icons.flag_outlined,
                    valueColor: status.color,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: colorScheme.outline.withValues(alpha: 0.18),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  dateRange,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.groups_2_outlined,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    groupName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color? valueColor;

  const _StatCell({
    required this.value,
    required this.label,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = valueColor ?? colorScheme.secondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
