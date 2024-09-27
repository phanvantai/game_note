import 'package:flutter/material.dart';

import '../../../../../../firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import '../../bloc/tournament_detail_bloc.dart';
import '../../matches/widgets/esport_match_team.dart';
import '../../widgets/medal_widget.dart';

class EsportLeagueResultItem extends StatelessWidget {
  final GNEsportLeagueStat e;
  final TournamentDetailState state;
  const EsportLeagueResultItem({
    Key? key,
    required this.e,
    required this.state,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
            bottom: BorderSide(
              color: Colors.grey,
              width: 1,
            ),
            top: BorderSide(
              color: Colors.grey,
              width: 1,
            )),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
              flex: 2,
              child: (e.user != null)
                  ? EsportMatchTeam(user: e.user!)
                  : const SizedBox()),
          Expanded(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  state.countMedalOfParticipants(e).toString(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 8.0),
                const MedalWidget(color: Colors.black54)
              ],
            ),
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                Text(
                  state.countValueOfParticipants(e).toString(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(width: 8.0),
                const Icon(Icons.attach_money)
              ],
            ),
          ),
        ],
      ),
    );
  }
}
