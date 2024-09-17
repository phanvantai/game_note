import 'package:flutter/material.dart';
import 'package:game_note/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:intl/intl.dart';

import 'esport_match_team.dart';

class EsportMatchItem extends StatelessWidget {
  final GNEsportMatch match;
  final Function()? onTap;
  final Function()? onLongPress;
  const EsportMatchItem({
    Key? key,
    required this.match,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          // border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              flex: 1,
              child: Text(
                match.isFinished
                    ? 'FT'
                    : DateFormat('d MMM').format(match.date),
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.normal),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: 6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (match.homeTeam != null)
                    EsportMatchTeam(user: match.homeTeam!),
                  if (match.awayTeam != null)
                    EsportMatchTeam(user: match.awayTeam!),
                ],
              ),
            ),
            Flexible(
              child: Column(
                children: [
                  Text(
                    match.homeScore.toString(),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    match.awayScore.toString(),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
