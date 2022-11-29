import 'package:flutter/material.dart';
import 'package:game_note/features/offline/presentation/models/player_stats.dart';

class TableItemView extends StatelessWidget {
  final PlayerStats model;
  const TableItemView({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.withOpacity(0.5),
        ),
      ),
      child: Flex(
        direction: Axis.horizontal,
        children: [
          Expanded(child: Center(child: Text(model.rank)), flex: 2),
          const SizedBox(width: 8),
          ClipRRect(
            child: Container(
              decoration: BoxDecoration(
                color: model.rank == '#' ? Colors.white : model.color,
                borderRadius: BorderRadius.circular(12),
              ),
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              model.name,
              style: TextStyle(
                  fontWeight:
                      model.rank == '#' ? FontWeight.bold : FontWeight.normal),
            ),
            flex: 9,
          ),
          Expanded(
            child: Center(
              child: Text(
                model.played,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            flex: 2,
          ),
          Expanded(
            child: Center(
              child: Text(
                model.wins,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            flex: 2,
          ),
          Expanded(
            child: Center(
              child: Text(
                model.draws,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            flex: 2,
          ),
          Expanded(
            child: Center(
              child: Text(
                model.losses.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            flex: 2,
          ),
          Expanded(
            child: Center(
                child: Text(
              model.goalsDifference == -10000
                  ? "GD"
                  : model.goalsDifference.toString(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            )),
            flex: 3,
          ),
          Expanded(
            child: Center(
              child: Text(
                model.points == -10000 ? "PTS" : model.points.toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            flex: 3,
          ),
        ],
      ),
    );
  }
}
