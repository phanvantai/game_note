import 'package:flutter/material.dart';

class TableScrollableColumnHeader extends StatelessWidget {
  const TableScrollableColumnHeader({
    Key? key,
    required this.tableHeaderDecor,
    required this.tableRowHeight,
    required this.tableNameColumnWidth,
    required this.tableStatsColumnWidth,
    required this.tableStatsTextStyle,
  }) : super(key: key);

  final BoxDecoration tableHeaderDecor;
  final double tableRowHeight;
  final double tableNameColumnWidth;
  final double tableStatsColumnWidth;
  final TextStyle tableStatsTextStyle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: tableHeaderDecor,
      height: tableRowHeight,
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          SizedBox(width: tableNameColumnWidth),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text('P', style: tableStatsTextStyle),
            ),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                'GD',
                style: tableStatsTextStyle,
              ),
            ),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                'PTS',
                style: tableStatsTextStyle,
              ),
            ),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                'W',
                style: tableStatsTextStyle,
              ),
            ),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                'D',
                style: tableStatsTextStyle,
              ),
            ),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                'L',
                style: tableStatsTextStyle,
              ),
            ),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                'F',
                style: tableStatsTextStyle,
              ),
            ),
          ),
          SizedBox(
            width: tableStatsColumnWidth,
            child: Center(
              child: Text(
                'A',
                style: tableStatsTextStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
