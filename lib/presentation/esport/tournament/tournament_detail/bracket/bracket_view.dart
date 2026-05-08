import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/update_match_score_dialog.dart';

import '../bloc/tournament_detail_bloc.dart';

class BracketView extends StatelessWidget {
  const BracketView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentDetailBloc, TournamentDetailState>(
      buildWhen: (prev, curr) => prev.matches != curr.matches,
      builder: (context, state) {
        final knockoutMatches = state.knockoutMatches;
        if (knockoutMatches.isEmpty) {
          return const _EmptyBracket();
        }

        // Group by knockoutRound
        final maxRound = knockoutMatches
            .map((m) => m.knockoutRound ?? 0)
            .reduce((a, b) => a > b ? a : b);

        final rounds = <int, List<GNEsportMatch>>{};
        for (final m in knockoutMatches) {
          final r = m.knockoutRound ?? 0;
          rounds.putIfAbsent(r, () => []).add(m);
        }
        for (final list in rounds.values) {
          list.sort((a, b) => (a.knockoutSlot ?? 0).compareTo(b.knockoutSlot ?? 0));
        }

        final roundLabels = _buildRoundLabels(maxRound);

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(maxRound + 1, (r) {
              final matchesInRound = rounds[r] ?? [];
              return _RoundColumn(
                label: roundLabels[r] ?? 'Vòng ${r + 1}',
                matches: matchesInRound,
                isLast: r == maxRound,
              );
            }),
          ),
        );
      },
    );
  }

  Map<int, String> _buildRoundLabels(int maxRound) {
    final labels = <int, String>{};
    labels[maxRound] = 'Chung kết';
    if (maxRound >= 1) labels[maxRound - 1] = 'Bán kết';
    if (maxRound >= 2) labels[maxRound - 2] = 'Tứ kết';
    return labels;
  }
}

class _EmptyBracket extends StatelessWidget {
  const _EmptyBracket();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_tree_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có bracket',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Bracket sẽ hiện sau khi giải đấu được tạo',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundColumn extends StatelessWidget {
  final String label;
  final List<GNEsportMatch> matches;
  final bool isLast;

  const _RoundColumn({
    required this.label,
    required this.matches,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      width: 180,
      margin: EdgeInsets.only(right: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colorScheme.secondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...matches.map((m) => _BracketMatchCard(match: m)),
        ],
      ),
    );
  }
}

class _BracketMatchCard extends StatelessWidget {
  final GNEsportMatch match;

  const _BracketMatchCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = context.read<TournamentDetailBloc>().state;
    final isAdmin = state.currentUserIsLeagueAdmin;
    final groupStageComplete = state.allGroupMatchesFinished;

    final homeName = match.homeTeam?.displayName ??
        (match.homeTeamId.isEmpty
            ? 'TBD'
            : match.homeTeamId.length > 4
                ? match.homeTeamId.substring(0, 4)
                : match.homeTeamId);
    final awayName = match.awayTeam?.displayName ??
        (match.awayTeamId.isEmpty
            ? 'TBD'
            : match.awayTeamId.length > 4
                ? match.awayTeamId.substring(0, 4)
                : match.awayTeamId);

    final homeWin =
        match.isFinished && (match.homeScore ?? 0) > (match.awayScore ?? 0);
    final awayWin =
        match.isFinished && (match.awayScore ?? 0) > (match.homeScore ?? 0);

    final hasGroupStage = state.groupIds.isNotEmpty;
    final canEdit = isAdmin &&
        match.homeTeamId.isNotEmpty &&
        match.awayTeamId.isNotEmpty &&
        (!hasGroupStage || groupStageComplete);

    return GestureDetector(
      onTap: canEdit ? () => showUpdateMatchScoreDialog(context, match) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: match.isFinished
                ? colorScheme.secondary.withValues(alpha: 0.3)
                : colorScheme.outline.withValues(alpha: 0.28),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            _BracketPlayer(
              name: homeName,
              score: match.isFinished ? match.homeScore : null,
              isWinner: homeWin,
              isTop: true,
            ),
            Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
            _BracketPlayer(
              name: awayName,
              score: match.isFinished ? match.awayScore : null,
              isWinner: awayWin,
              isTop: false,
            ),
          ],
        ),
      ),
    );
  }

}

class _BracketPlayer extends StatelessWidget {
  final String name;
  final int? score;
  final bool isWinner;
  final bool isTop;

  const _BracketPlayer({
    required this.name,
    required this.score,
    required this.isWinner,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isWinner ? colorScheme.secondary.withValues(alpha: 0.1) : null,
        borderRadius: BorderRadius.vertical(
          top: isTop ? const Radius.circular(9) : Radius.zero,
          bottom: !isTop ? const Radius.circular(9) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isWinner ? FontWeight.w700 : FontWeight.normal,
                color: isWinner ? colorScheme.secondary : null,
              ),
            ),
          ),
          if (score != null)
            Text(
              '$score',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: isWinner ? colorScheme.secondary : colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

