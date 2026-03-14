import 'package:flutter/material.dart';
import 'package:pes_arena/offline/domain/entities/result_model.dart';

class PlayerScoreView extends StatelessWidget {
  final ResultModel model;
  const PlayerScoreView({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: model.playerModel.color,
              borderRadius: BorderRadius.circular(8),
            ),
            width: 24,
            height: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              model.playerModel.fullname,
              style: textTheme.bodyLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            model.score != null ? model.score.toString() : '__',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
