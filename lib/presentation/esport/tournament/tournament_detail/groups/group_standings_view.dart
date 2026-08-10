import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/update_match_score_dialog.dart';

import '../bloc/tournament_detail_bloc.dart';

class _GroupStandingsData extends Equatable {
  final List<GNEsportMatch> matches;
  final List<List<Object?>> matchRenderData;
  final List<GNEsportLeagueStat> participants;
  final String? selectedGroupId;
  final int advanceCount;
  final bool canEdit;
  final Set<String> pendingMatchIds;
  final Map<String, String> matchErrorsById;

  const _GroupStandingsData({
    required this.matches,
    required this.matchRenderData,
    required this.participants,
    required this.selectedGroupId,
    required this.advanceCount,
    required this.canEdit,
    required this.pendingMatchIds,
    required this.matchErrorsById,
  });

  factory _GroupStandingsData.fromState(TournamentDetailState state) {
    final matches = List<GNEsportMatch>.unmodifiable(
      state.matches.where((match) => match.phase == 'group'),
    );
    final matchIds = matches.map((match) => match.id).toSet();

    return _GroupStandingsData(
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
      participants: List<GNEsportLeagueStat>.unmodifiable(
        state.participants.where((participant) => participant.groupId != null),
      ),
      selectedGroupId: state.selectedGroupId,
      advanceCount: state.league?.advanceCount ?? 2,
      canEdit: state.currentUserIsLeagueAdmin,
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

  List<String> get groupIds {
    final ids = <String>{};
    for (final match in matches) {
      if (match.groupId != null) ids.add(match.groupId!);
    }
    return ids.toList()..sort();
  }

  List<GNEsportMatch> groupMatches(String groupId) {
    return matches.where((match) => match.groupId == groupId).toList();
  }

  List<GNEsportLeagueStat> groupStats(String groupId) {
    return participants.where((stat) => stat.groupId == groupId).toList();
  }

  @override
  List<Object?> get props => [
    matches,
    matchRenderData,
    participants,
    selectedGroupId,
    advanceCount,
    canEdit,
    pendingMatchIds,
    matchErrorsById,
  ];
}

class GroupStandingsView extends StatelessWidget {
  const GroupStandingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      TournamentDetailBloc,
      TournamentDetailState,
      _GroupStandingsData
    >(
      selector: _GroupStandingsData.fromState,
      builder: (context, data) {
        final groupIds = data.groupIds;
        if (groupIds.isEmpty) {
          return const _EmptyGroups();
        }

        final selectedGroup = data.selectedGroupId ?? groupIds.first;

        return Column(
          children: [
            _GroupTabBar(
              groupIds: groupIds,
              selected: selectedGroup,
              onSelect: (id) =>
                  context.read<TournamentDetailBloc>().add(SelectGroup(id)),
            ),
            Expanded(
              child: KeyedSubtree(
                key: const Key('tournament-group-content'),
                child: _GroupContent(
                  groupId: selectedGroup,
                  stats: data.groupStats(selectedGroup),
                  matches: data.groupMatches(selectedGroup),
                  advanceCount: data.advanceCount,
                  canEdit: data.canEdit,
                  pendingMatchIds: data.pendingMatchIds,
                  matchErrorsById: data.matchErrorsById,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyGroups extends StatelessWidget {
  const _EmptyGroups();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.table_chart_outlined,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Chưa có vòng bảng',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTabBar extends StatelessWidget {
  final List<String> groupIds;
  final String selected;
  final ValueChanged<String> onSelect;

  const _GroupTabBar({
    required this.groupIds,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 42,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        scrollDirection: Axis.horizontal,
        children: groupIds.map((id) {
          final isSelected = id == selected;
          return InkWell(
            onTap: () => onSelect(id),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.only(right: 14, top: 7, bottom: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: isSelected
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                    child: Text(context.l10n.tournamentGroupLabel(id)),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: isSelected ? 20 : 0,
                    height: 2,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _GroupContent extends StatelessWidget {
  final String groupId;
  final List<GNEsportLeagueStat> stats;
  final List<GNEsportMatch> matches;
  final int advanceCount;
  final bool canEdit;
  final Set<String> pendingMatchIds;
  final Map<String, String> matchErrorsById;

  const _GroupContent({
    required this.groupId,
    required this.stats,
    required this.matches,
    required this.advanceCount,
    required this.canEdit,
    required this.pendingMatchIds,
    required this.matchErrorsById,
  });

  @override
  Widget build(BuildContext context) {
    final sortedStats = List<GNEsportLeagueStat>.from(stats)
      ..sort((a, b) {
        final pts = b.points.compareTo(a.points);
        if (pts != 0) return pts;
        return b.goalDifference.compareTo(a.goalDifference);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StandingsTable(stats: sortedStats, advanceCount: advanceCount),
          const SizedBox(height: 16),
          _GroupMatchesList(
            groupId: groupId,
            matches: matches,
            canEdit: canEdit,
            pendingMatchIds: pendingMatchIds,
            matchErrorsById: matchErrorsById,
          ),
        ],
      ),
    );
  }
}

class _StandingsTable extends StatelessWidget {
  final List<GNEsportLeagueStat> stats;
  final int advanceCount;

  const _StandingsTable({required this.stats, required this.advanceCount});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _TableHeader(),
          ...stats.asMap().entries.map((e) {
            final i = e.key;
            final stat = e.value;
            final isAdvance = i < advanceCount;
            final isLast = i == stats.length - 1;
            return Column(
              children: [
                if (i == advanceCount && stats.length > advanceCount)
                  Divider(
                    height: 1,
                    thickness: 2,
                    color: colorScheme.secondary.withValues(alpha: 0.28),
                  ),
                _TableRow(
                  rank: i + 1,
                  stat: stat,
                  isAdvance: isAdvance,
                  isLast: isLast,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Expanded(
            child: Text(
              'Cầu thủ',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (final h in ['W', 'D', 'L', 'GD', 'Pts'])
            SizedBox(
              width: 30,
              child: Text(
                h,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.secondary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final int rank;
  final GNEsportLeagueStat stat;
  final bool isAdvance;
  final bool isLast;

  const _TableRow({
    required this.rank,
    required this.stat,
    required this.isAdvance,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = stat.user?.displayName ?? stat.userId;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isAdvance ? colorScheme.secondary.withValues(alpha: 0.05) : null,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(8))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            child: Text(
              '$rank',
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: isAdvance
                    ? colorScheme.secondary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: isAdvance ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
          for (final v in [
            stat.wins,
            stat.draws,
            stat.losses,
            stat.goalDifference,
            stat.points,
          ])
            SizedBox(
              width: 30,
              child: Text(
                '${v >= 0 ? '' : ''}$v',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _valueColor(colorScheme, v),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color? _valueColor(ColorScheme cs, int value) {
    if (value > 0) return cs.primary;
    if (value < 0) return cs.error;
    return null;
  }
}

class _GroupMatchesList extends StatelessWidget {
  final String groupId;
  final List<GNEsportMatch> matches;
  final bool canEdit;
  final Set<String> pendingMatchIds;
  final Map<String, String> matchErrorsById;

  const _GroupMatchesList({
    required this.groupId,
    required this.matches,
    required this.canEdit,
    required this.pendingMatchIds,
    required this.matchErrorsById,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                context.l10n.tournamentGroupMatchesTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (canEdit)
              TextButton.icon(
                onPressed: () => context.read<TournamentDetailBloc>().add(
                  GenerateGroupRound(groupId),
                ),
                icon: const Icon(Icons.add, size: 16),
                label: Text(context.l10n.tournamentAddRound),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...matches.map((m) {
          final homeName = m.homeTeam?.displayName ?? m.homeTeamId;
          final awayName = m.awayTeam?.displayName ?? m.awayTeamId;
          final isPending = pendingMatchIds.contains(m.id);
          final savingLabel = context.l10n.tournamentSavingMatch;
          final visibleError = matchErrorsById[m.id]?.trim();
          return Semantics(
            container: true,
            label: isPending ? savingLabel : null,
            enabled: canEdit && !isPending,
            explicitChildNodes: isPending,
            child: GestureDetector(
              onTap: canEdit && !isPending
                  ? () => showUpdateMatchScoreDialog(context, m)
                  : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            homeName,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: m.isFinished
                                ? colorScheme.secondary.withValues(alpha: 0.12)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            m.isFinished
                                ? '${m.homeScore} – ${m.awayScore}'
                                : 'vs',
                            style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: m.isFinished
                                  ? colorScheme.secondary
                                  : colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            awayName,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.end,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isPending)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 6),
                            ExcludeSemantics(
                              child: Text(
                                savingLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (visibleError != null && visibleError.isNotEmpty)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
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
        }),
      ],
    );
  }
}
