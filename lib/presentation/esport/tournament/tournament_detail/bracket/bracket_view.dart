import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/update_match_score_dialog.dart';

import '../bloc/tournament_detail_bloc.dart';

class _BracketViewData extends Equatable {
  final List<GNEsportMatch> matches;
  final List<List<Object?>> matchRenderData;
  final bool canEditMatches;
  final Set<String> pendingMatchIds;
  final Map<String, String> matchErrorsById;

  const _BracketViewData({
    required this.matches,
    required this.matchRenderData,
    required this.canEditMatches,
    required this.pendingMatchIds,
    required this.matchErrorsById,
  });

  factory _BracketViewData.fromState(TournamentDetailState state) {
    final matches = List<GNEsportMatch>.unmodifiable(state.knockoutMatches);
    final matchIds = matches.map((match) => match.id).toSet();

    return _BracketViewData(
      matches: matches,
      matchRenderData: List.unmodifiable(
        matches.map(
          (match) => List<Object?>.unmodifiable([
            match,
            match.homeTeam,
            match.awayTeam,
          ]),
        ),
      ),
      canEditMatches:
          state.currentUserIsLeagueAdmin &&
          (state.groupIds.isEmpty || state.allGroupMatchesFinished),
      pendingMatchIds: Set.unmodifiable(
        state.pendingMatchIds.where(matchIds.contains),
      ),
      matchErrorsById: Map.unmodifiable(
        Map.fromEntries(
          state.matchErrorsById.entries.where(
            (entry) => matchIds.contains(entry.key),
          ),
        ),
      ),
    );
  }

  @override
  List<Object?> get props => [
    matches,
    matchRenderData,
    canEditMatches,
    pendingMatchIds,
    matchErrorsById,
  ];
}

class BracketView extends StatelessWidget {
  const BracketView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      TournamentDetailBloc,
      TournamentDetailState,
      _BracketViewData
    >(
      selector: _BracketViewData.fromState,
      builder: (context, data) {
        final knockoutMatches = data.matches;
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
          list.sort(
            (a, b) => (a.knockoutSlot ?? 0).compareTo(b.knockoutSlot ?? 0),
          );
        }

        final roundLabels = _buildRoundLabels(maxRound);

        return KeyedSubtree(
          key: const Key('tournament-bracket-rounds'),
          child: SingleChildScrollView(
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
                  canEditMatches: data.canEditMatches,
                  pendingMatchIds: data.pendingMatchIds,
                  matchErrorsById: data.matchErrorsById,
                );
              }),
            ),
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
  final bool canEditMatches;
  final Set<String> pendingMatchIds;
  final Map<String, String> matchErrorsById;

  const _RoundColumn({
    required this.label,
    required this.matches,
    required this.isLast,
    required this.canEditMatches,
    required this.pendingMatchIds,
    required this.matchErrorsById,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: EdgeInsets.only(right: isLast ? 0 : 12),
      child: SizedBox(
        width: 180,
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
            ...matches.map(
              (match) => _BracketMatchCard(
                match: match,
                canEdit: canEditMatches,
                isPending: pendingMatchIds.contains(match.id),
                errorMessage: matchErrorsById[match.id],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BracketMatchCard extends StatelessWidget {
  final GNEsportMatch match;
  final bool canEdit;
  final bool isPending;
  final String? errorMessage;

  const _BracketMatchCard({
    required this.match,
    required this.canEdit,
    required this.isPending,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final savingLabel = context.l10n.tournamentSavingMatch;
    final visibleError = errorMessage?.trim();

    final homeName =
        match.homeTeam?.displayName ??
        (match.homeTeamId.isEmpty
            ? 'TBD'
            : match.homeTeamId.length > 4
            ? match.homeTeamId.substring(0, 4)
            : match.homeTeamId);
    final awayName =
        match.awayTeam?.displayName ??
        (match.awayTeamId.isEmpty
            ? 'TBD'
            : match.awayTeamId.length > 4
            ? match.awayTeamId.substring(0, 4)
            : match.awayTeamId);

    final homeWin =
        match.isFinished && (match.homeScore ?? 0) > (match.awayScore ?? 0);
    final awayWin =
        match.isFinished && (match.awayScore ?? 0) > (match.homeScore ?? 0);

    final hasPlayableTeams =
        match.homeTeamId.isNotEmpty && match.awayTeamId.isNotEmpty;
    final interactionEnabled = canEdit && hasPlayableTeams && !isPending;

    return Semantics(
      container: true,
      label: isPending ? savingLabel : null,
      enabled: interactionEnabled,
      explicitChildNodes: isPending,
      child: GestureDetector(
        onTap: interactionEnabled
            ? () => showUpdateMatchScoreDialog(context, match)
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Color.alphaBlend(
              (match.isFinished ? colorScheme.secondary : colorScheme.outline)
                  .withValues(alpha: match.isFinished ? 0.07 : 0.02),
              colorScheme.surfaceContainerHighest,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _BracketPlayer(
                name: homeName,
                score: match.isFinished ? match.homeScore : null,
                isWinner: homeWin,
                isTop: true,
              ),
              Divider(
                height: 1,
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
              _BracketPlayer(
                name: awayName,
                score: match.isFinished ? match.awayScore : null,
                isWinner: awayWin,
                isTop: false,
              ),
              if (isPending)
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                  child: ExcludeSemantics(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const SizedBox.square(
                          dimension: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            savingLabel,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (visibleError != null && visibleError.isNotEmpty)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                    child: Text(
                      visibleError,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.error,
                      ),
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
                color: isWinner
                    ? colorScheme.secondary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
