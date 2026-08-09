import 'package:flutter/material.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:intl/intl.dart';

import 'esport_match_team.dart';

class EsportMatchItem extends StatelessWidget {
  final GNEsportMatch match;
  final Function()? onTap;
  final Function()? onLongPress;
  const EsportMatchItem({
    super.key,
    required this.match,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: colorScheme.surfaceContainerHighest,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      match.isFinished
                          ? 'FT'
                          : DateFormat('d MMM').format(match.date),
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: match.isFinished
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (match.matchday != null)
                      Text(
                        context.l10n.tournamentMatchdayBadge(match.matchday!),
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: colorScheme.onSurface.withValues(alpha: 0.38),
                        ),
                      ),
                  ],
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
