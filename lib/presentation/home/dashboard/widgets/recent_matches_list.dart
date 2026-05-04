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
    if (matches.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: matches
          .map(
            (match) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () =>
                    context.push(Routing.tournamentDetailPath(match.leagueId)),
                leading: Icon(match.result.icon, color: match.result.color),
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
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          )
          .toList(),
    );
  }
}
