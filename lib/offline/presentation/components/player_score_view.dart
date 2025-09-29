import 'package:flutter/material.dart';
import 'package:pes_arena/offline/domain/entities/result_model.dart';

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
                color: model.playerModel.color,
                borderRadius: BorderRadius.circular(12),
              ),
              width: 24,
              height: 24,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            model.playerModel.fullname,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.normal,
            ),
          ),
          const Spacer(),
          Text(
            model.score != null ? model.score.toString() : '__',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
