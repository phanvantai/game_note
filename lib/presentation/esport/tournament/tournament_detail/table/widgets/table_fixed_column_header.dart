import 'package:flutter/material.dart';

import '../table_view.dart';

class TableFixedColumnHeader extends StatelessWidget {
  const TableFixedColumnHeader({
    Key? key,
    required this.tableIconColumnWidth,
    required this.tableRowHeight,
  }) : super(key: key);

  final double tableIconColumnWidth;
  final double tableRowHeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ranking
        Container(
          decoration: BoxDecoration(
            color: EsportTableView.tableBackgroundColor,
            border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
                top: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1)),
          ),
          alignment: Alignment.center,
          width: tableIconColumnWidth - 4,
          height: tableRowHeight,
          child: const Text(
            '#',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: EsportTableView.tableBackgroundColor,
            border: Border(
                bottom: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1),
                top: BorderSide(color: Theme.of(context).colorScheme.outline, width: 1)),
          ),
          alignment: Alignment.center,
          width: tableIconColumnWidth + 4,
          height: tableRowHeight,
          child: const Text(
            'TEAM',
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
