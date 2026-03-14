import 'package:flutter/material.dart';

import '../../../../../../firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';

class TableScrollableColumnItem extends StatelessWidget {
  const TableScrollableColumnItem({
    Key? key,
    required this.tableItemDecor,
    required this.tableRowHeight,
    required this.tableNameColumnWidth,
    required this.stats,
    required this.tableStatsColumnWidth,
  }) : super(key: key);

  final BoxDecoration tableItemDecor;
  final double tableRowHeight;
  final double tableNameColumnWidth;
  final GNEsportLeagueStat stats;
  final double tableStatsColumnWidth;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final statStyle = textTheme.bodySmall?.copyWith(
      fontWeight: FontWeight.w600,
    );

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
              style: textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          for (final value in [
            stats.matchesPlayed,
            stats.goalDifference,
            stats.points,
            stats.wins,
            stats.draws,
            stats.losses,
            stats.goals,
            stats.goalsConceded,
          ])
            SizedBox(
              width: tableStatsColumnWidth,
              child: Center(
                child: Text(value.toString(), style: statStyle),
              ),
            ),
        ],
      ),
    );
  }
}
