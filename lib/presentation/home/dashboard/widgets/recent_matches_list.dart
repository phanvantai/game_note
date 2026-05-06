import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pes_arena/routing.dart';
import 'package:pes_arena/widgets/gn_circle_avatar.dart';

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
      children: matches.map((match) => _MatchItem(match: match)).toList(),
    );
  }
}

class _MatchItem extends StatelessWidget {
  final RecentMatchSummary match;
  const _MatchItem({required this.match});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final resultColor = match.result.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: resultColor.withValues(alpha: 0.22)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () =>
              context.push(Routing.tournamentDetailPath(match.leagueId)),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: resultColor.withValues(alpha: 0.55),
                      width: 2,
                    ),
                  ),
                  child: match.opponentPhotoUrl != null
                      ? GNCircleAvatar(
                          photoUrl: match.opponentPhotoUrl,
                          size: 40,
                        )
                      : _InitialsAvatar(
                          name: match.opponentDisplayName,
                          size: 40,
                          accent: resultColor,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        match.leagueName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        match.opponentDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        DateFormat('dd/MM/yyyy').format(match.date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: resultColor.withValues(alpha: 0.38),
                        ),
                      ),
                      child: Text(
                        match.result.label,
                        style: TextStyle(
                          color: resultColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${match.userScore} - ${match.opponentScore}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color accent;

  const _InitialsAvatar({
    required this.name,
    required this.size,
    required this.accent,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: accent,
          fontSize: size * 0.33,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
