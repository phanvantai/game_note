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
    required this.tableStatsTextStyle,
  }) : super(key: key);

  final BoxDecoration tableItemDecor;
  final double tableRowHeight;
  final double tableNameColumnWidth;
  final GNEsportLeagueStat stats;
  final double tableStatsColumnWidth;
  final TextStyle tableStatsTextStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: tableItemDecor,
      height: tableRowHeight,
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          SizedBox(
            width: tableNameColumnWidth,
            child: Text(stats.user?.displayName ??
                stats.user?.email ??
                stats.user?.phoneNumber ??
                ''),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                stats.matchesPlayed.toString(),
                style: tableStatsTextStyle,
              ),
            ),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                stats.goalDifference.toString(),
                style: tableStatsTextStyle,
              ),
            ),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                stats.points.toString(),
                style: tableStatsTextStyle,
              ),
            ),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                stats.wins.toString(),
                style: tableStatsTextStyle,
              ),
            ),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                stats.draws.toString(),
                style: tableStatsTextStyle,
              ),
            ),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                stats.losses.toString(),
                style: tableStatsTextStyle,
              ),
            ),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                stats.goals.toString(),
                style: tableStatsTextStyle,
              ),
            ),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                stats.goalsConceded.toString(),
                style: tableStatsTextStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
