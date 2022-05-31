import 'package:flutter/material.dart';
import 'package:game_note/model/dump_leagues.dart';

import 'club_view.dart';

class LeagueView extends StatelessWidget {
  final LeagueModel league;
  final VoidCallback? callback;
  const LeagueView({
    Key? key,
    required this.league,
    this.callback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print("build ${league.title}");
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 50.0,
          color: Colors.greenAccent[700],
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          alignment: Alignment.center,
          child: Text(
            league.title.toUpperCase(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var item in league.clubs)
              ClubView(
                model: item,
                onClick: (vm) {
                  if (callback != null) {
                    callback!();
                  }
                },
              )
          ],
        )
      ],
    );
  }
}
