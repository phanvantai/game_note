import 'package:flutter/material.dart';
import 'package:pes_arena/offline/presentation/models/player_stats.dart';

class TableItemView extends StatelessWidget {
  final PlayerStats model;
  final bool isHeader;
  final bool isEven;
  const TableItemView({
    Key? key,
    required this.model,
    this.isHeader = false,
    this.isEven = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final headerStyle = textTheme.labelSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface.withValues(alpha: 0.7),
    );
    final cellStyle = textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final nameStyle = isHeader
        ? headerStyle
        : textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: isHeader
            ? colorScheme.surfaceContainerHighest
            : isEven
                ? colorScheme.surface
                : colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
      ),
      child: Flex(
        direction: Axis.horizontal,
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                model.rank,
                style: isHeader ? headerStyle : cellStyle,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 9,
            child: Text(
              model.name,
              style: nameStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                model.played,
                style: isHeader ? headerStyle : cellStyle,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                model.wins,
                style: isHeader ? headerStyle : cellStyle,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                model.draws,
                style: isHeader ? headerStyle : cellStyle,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                model.losses.toString(),
                style: isHeader ? headerStyle : cellStyle,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
                child: Text(
              model.goalsDifference == -10000
                  ? "GD"
                  : model.goalsDifference.toString(),
              style: isHeader ? headerStyle : cellStyle,
            )),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                model.points == -10000 ? "PTS" : model.points.toString(),
                style: isHeader ? headerStyle : cellStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
