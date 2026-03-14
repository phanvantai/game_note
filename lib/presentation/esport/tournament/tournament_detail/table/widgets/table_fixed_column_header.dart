import 'package:flutter/material.dart';

class TableFixedColumnHeader extends StatelessWidget {
  const TableFixedColumnHeader({
    Key? key,
    required this.tableIconColumnWidth,
    required this.tableRowHeight,
    required this.decoration,
  }) : super(key: key);

  final double tableIconColumnWidth;
  final double tableRowHeight;
  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: decoration,
          alignment: Alignment.center,
          width: tableIconColumnWidth - 4,
          height: tableRowHeight,
          child: Text('#', style: textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          )),
        ),
        Container(
          decoration: decoration,
          alignment: Alignment.center,
          width: tableIconColumnWidth + 4,
          height: tableRowHeight,
          child: Text('', style: textTheme.labelSmall),
        ),
      ],
    );
  }
}
