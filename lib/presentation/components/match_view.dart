import 'package:flutter/material.dart';
import 'package:game_note/presentation/components/player_score_view.dart';
import 'package:game_note/presentation/models/match.dart';

class MatchView extends StatelessWidget {
  final Match model;
  const MatchView({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          const ClipRRect(child: Icon(Icons.people_alt_rounded)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                PlayerScoreView(model: model.matchModel.home),
                PlayerScoreView(model: model.matchModel.away),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
