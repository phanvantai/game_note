import 'package:flutter/material.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/presentation/components/match_view.dart';

class ListMatchesView extends StatelessWidget {
  final List<MatchModel> list;
  const ListMatchesView({Key? key, required this.list}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: ((context, index) {
        return MatchView(
          model: list[index],
          callback: () {
            print('abcdef');
          },
        );
      }),
    );
  }
}
