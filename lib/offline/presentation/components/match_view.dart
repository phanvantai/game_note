import 'package:flutter/material.dart';
import 'package:pes_arena/offline/domain/entities/match_model.dart';
import 'package:pes_arena/offline/presentation/components/player_score_view.dart';

class MatchView extends StatelessWidget {
  final MatchModel model;
  final Function(MatchModel)? callback;
  final Function(MatchModel)? reUpdateMatchCallback;
  const MatchView({
    Key? key,
    required this.model,
    this.callback,
    this.reUpdateMatchCallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onLongPress: () {
        if (reUpdateMatchCallback != null) {
          reUpdateMatchCallback!(model);
        }
      },
      onTap: model.status == false
          ? () {
              if (callback != null) {
                callback!(model);
              }
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.15),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            PlayerScoreView(model: model.home!),
            PlayerScoreView(model: model.away!),
          ],
        ),
      ),
    );
  }
}
