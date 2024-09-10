import 'package:flutter/material.dart';
import 'package:game_note/offline/domain/entities/match_model.dart';
import 'package:game_note/offline/presentation/components/player_score_view.dart';

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
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
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
