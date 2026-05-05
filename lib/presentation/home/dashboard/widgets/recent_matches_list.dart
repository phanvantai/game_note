import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pes_arena/routing.dart';

import '../models/recent_match_summary.dart';
import 'form_dots_row.dart';

class RecentMatchesList extends StatelessWidget {
  final List<RecentMatchSummary> matches;

  const RecentMatchesList({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (matches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: matches
          .map(
            (match) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.52,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.38),
                ),
              ),
              child: ListTile(
                onTap: () =>
                    context.push(Routing.tournamentDetailPath(match.leagueId)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: match.result.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    match.result.icon,
                    color: match.result.color,
                    size: 20,
                  ),
                ),
                title: Text(
                  '${DateFormat('dd/MM').format(match.date)} · ${match.leagueName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Bạn ${match.userScore} - ${match.opponentScore} '
                  '${match.opponentDisplayName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
