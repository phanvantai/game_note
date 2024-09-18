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
          decoration: const BoxDecoration(
            color: EsportTableView.tableBackgroundColor,
            border: Border(
                bottom: BorderSide(color: Colors.grey, width: 1),
                top: BorderSide(color: Colors.grey, width: 1)),
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
          decoration: const BoxDecoration(
            color: EsportTableView.tableBackgroundColor,
            border: Border(
                bottom: BorderSide(color: Colors.grey, width: 1),
                top: BorderSide(color: Colors.grey, width: 1)),
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
