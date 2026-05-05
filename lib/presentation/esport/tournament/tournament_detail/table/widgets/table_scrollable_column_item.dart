import 'package:flutter/material.dart';

import '../../../../../../firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';

class TableScrollableColumnItem extends StatelessWidget {
  const TableScrollableColumnItem({
    super.key,
    required this.tableItemDecor,
    required this.tableRowHeight,
    required this.tableNameColumnWidth,
    required this.stats,
    required this.tableStatsColumnWidth,
    required this.rank,
  });

  final BoxDecoration tableItemDecor;
  final double tableRowHeight;
  final double tableNameColumnWidth;
  final GNEsportLeagueStat stats;
  final double tableStatsColumnWidth;
  final int rank;

  static const _gold = Color(0xFFFBBF24);
  static const _silver = Color(0xFF9CA3AF);
  static const _bronze = Color(0xFFCD853F);

  Color? _rankAccent() => switch (rank) {
        1 => _gold,
        2 => _silver,
        3 => _bronze,
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _rankAccent();

    final values = [
      stats.matchesPlayed,
      stats.goalDifference,
      stats.points,
      stats.wins,
      stats.draws,
      stats.losses,
      stats.goals,
      stats.goalsConceded,
    ];

    return Container(
      decoration: tableItemDecor,
      height: tableRowHeight,
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          SizedBox(
            width: tableNameColumnWidth,
            child: Text(
              stats.user?.displayName ??
                  stats.user?.email ??
                  stats.user?.phoneNumber ??
                  '',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: rank <= 3 ? FontWeight.w700 : FontWeight.w500,
                color: accent ?? colorScheme.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          for (int i = 0; i < values.length; i++)
            SizedBox(
              width: tableStatsColumnWidth,
              child: Center(child: _buildStatCell(context, i, values[i])),
            ),
        ],
      ),
    );
  }

  Widget _buildStatCell(BuildContext context, int index, int value) {
    final colorScheme = Theme.of(context).colorScheme;

    // PTS (index 2) — highlighted badge
    if (index == 2) {
      final accent = _rankAccent();
      final badgeColor = accent != null
          ? accent.withValues(alpha: 0.18)
          : colorScheme.secondary.withValues(alpha: 0.13);
      final textColor = accent ?? colorScheme.secondary;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          value.toString(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
      );
    }

    // GD (index 1) — color coded
    if (index == 1) {
      final color = value > 0
          ? const Color(0xFF16A34A)
          : value < 0
              ? colorScheme.error
              : colorScheme.onSurface.withValues(alpha: 0.45);
      return Text(
        value > 0 ? '+$value' : value.toString(),
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      );
    }

    // Default stat cell — P (index 0) gets same size as PTS/GD
    final fontSize = index == 0 ? 15.0 : 13.0;
    return Text(
      value.toString(),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface.withValues(alpha: 0.75),
      ),
    );
  }
}
