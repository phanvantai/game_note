import 'package:flutter/material.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/domain/entities/round_model.dart';
import 'package:game_note/presentation/components/match_view.dart';

class ListRoundsView extends StatelessWidget {
  final List<RoundModel> list;
  final Function(MatchModel)? callback;
  final bool status;
  const ListRoundsView({
    Key? key,
    required this.list,
    this.callback,
    this.status = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: list.length,
      itemBuilder: ((context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (var match in list[index].matches)
                if (match.status == status)
                  MatchView(
                    model: match,
                    callback: callback,
                  )
            ],
          ),
        );
      }),
    );
  }
}
