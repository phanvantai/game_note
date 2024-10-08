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
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          // border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey[200],
        ),
        // padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Center(
                      child: Text(
                        match.isFinished
                            ? 'FT'
                            : DateFormat('d MMM').format(match.date),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.normal),
                      ),
                    ),
                  ),
                  Expanded(
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
                    flex: 1,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            match.isFinished ? match.homeScore.toString() : '-',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            match.isFinished ? match.awayScore.toString() : '-',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (match.medals != null && match.medals! > 0)
              Positioned(
                right: 0,
                child: Container(
                  height: double.maxFinite,
                  width: 4,
                  color: Colors.red[300],
                ),
              )
          ],
        ),
      ),
    );
  }
}
