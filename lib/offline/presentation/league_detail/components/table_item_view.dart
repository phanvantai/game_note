import 'package:flutter/material.dart';
import 'package:game_note/offline/presentation/models/player_stats.dart';

class TableItemView extends StatelessWidget {
  final PlayerStats model;
  const TableItemView({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isTitle = model.rank == '#';
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.5),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 9,
            child: Text(
              model.name,
              style: TextStyle(
                fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
                fontSize: isTitle ? 16 : 20,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                model.played,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                model.wins,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                model.draws,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                model.losses.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
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
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                model.points == -10000 ? "PTS" : model.points.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
