import 'package:flutter/material.dart';

class TableFixedColumnHeader extends StatelessWidget {
  const TableFixedColumnHeader({
    super.key,
    required this.tableIconColumnWidth,
    required this.tableRowHeight,
    required this.decoration,
  });

  final double tableIconColumnWidth;
  final double tableRowHeight;
  final BoxDecoration decoration;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: decoration,
          alignment: Alignment.center,
          width: tableIconColumnWidth - 4,
          height: tableRowHeight,
          child: Text(
            '#',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface.withValues(alpha: 0.9),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: decoration,
          alignment: Alignment.center,
          width: tableIconColumnWidth + 4,
          height: tableRowHeight,
          child: Icon(
            Icons.person_outline,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
