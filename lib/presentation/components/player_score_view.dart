import 'package:flutter/material.dart';
import 'package:game_note/core/constants/constants.dart';
import 'package:game_note/domain/entities/result_model.dart';

class PlayerScoreView extends StatelessWidget {
  final ResultModel model;
  const PlayerScoreView({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          ClipRRect(
            child: Container(
              decoration: BoxDecoration(
                color: randomObject(Colors.primaries),
                borderRadius: BorderRadius.circular(12),
              ),
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            model.playerModel.name,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            model.score.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
