import 'package:flutter/material.dart';

class TableScrollableColumnHeader extends StatelessWidget {
  const TableScrollableColumnHeader({
    super.key,
    required this.tableHeaderDecor,
    required this.tableRowHeight,
    required this.tableNameColumnWidth,
    required this.tableStatsColumnWidth,
  });

  final BoxDecoration tableHeaderDecor;
  final double tableRowHeight;
  final double tableNameColumnWidth;
  final double tableStatsColumnWidth;

  static const _labels = ['P', 'GD', 'PTS', 'W', 'D', 'L', 'F', 'A'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: tableHeaderDecor,
      height: tableRowHeight,
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          SizedBox(width: tableNameColumnWidth),
          for (final label in _labels)
            SizedBox(
              width: tableStatsColumnWidth,
              child: Center(
                child: label == 'PTS'
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: colorScheme.onSurface,
                            letterSpacing: 0.3,
                          ),
                        ),
                      )
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}
