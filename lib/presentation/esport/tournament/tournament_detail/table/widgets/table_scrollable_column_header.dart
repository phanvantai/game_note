import 'package:flutter/material.dart';

class TableScrollableColumnHeader extends StatelessWidget {
  const TableScrollableColumnHeader({
    Key? key,
    required this.tableHeaderDecor,
    required this.tableRowHeight,
    required this.tableNameColumnWidth,
    required this.tableStatsColumnWidth,
  }) : super(key: key);

  final BoxDecoration tableHeaderDecor;
  final double tableRowHeight;
  final double tableNameColumnWidth;
  final double tableStatsColumnWidth;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
        );

    return Container(
      decoration: tableHeaderDecor,
      height: tableRowHeight,
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          SizedBox(width: tableNameColumnWidth),
          for (final label in ['P', 'GD', 'PTS', 'W', 'D', 'L', 'F', 'A'])
            SizedBox(
              width: tableStatsColumnWidth,
              child: Center(child: Text(label, style: style)),
            ),
        ],
      ),
    );
  }
}
