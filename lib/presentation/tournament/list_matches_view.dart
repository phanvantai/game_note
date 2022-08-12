import 'package:flutter/material.dart';
import 'package:game_note/presentation/components/match_view.dart';
import 'package:game_note/presentation/models/match.dart';

class ListMatchesView extends StatelessWidget {
  const ListMatchesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: Match.dump.length,
      itemBuilder: ((context, index) {
        return MatchView(model: Match.dump[index]);
      }),
    );
  }
}
