import 'package:flutter/material.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasMedals = match.medals != null && match.medals! > 0;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surface,
          border: Border.all(
            color: hasMedals
                ? colorScheme.secondary.withValues(alpha: 0.4)
                : colorScheme.outline.withValues(alpha: 0.2),
            width: hasMedals ? 1.5 : 0.5,
          ),
        ),
        child: Padding(
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
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                      fontWeight:
                          match.isFinished ? FontWeight.w600 : FontWeight.normal,
                    ),
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
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        match.isFinished ? match.awayScore.toString() : '-',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
