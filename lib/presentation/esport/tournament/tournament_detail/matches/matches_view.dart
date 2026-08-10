import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/fixture_grouping.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/create_custom_match_dialog.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/update_match_score_dialog.dart';

import '../bloc/tournament_detail_bloc.dart';

/// A row in the flattened fixtures list: either a matchday header or a match.
sealed class _FixtureRow {
  const _FixtureRow();
}

class _HeaderRow extends _FixtureRow {
  /// Null for the trailing "other matches" bucket.
  final int? matchday;
  const _HeaderRow(this.matchday);
}

class _MatchRow extends _FixtureRow {
  final GNEsportMatch match;
  const _MatchRow(this.match);
}

class _MatchesViewData extends Equatable {
  final List<GNEsportMatch> matches;
  final List<List<Object?>> matchRenderData;
  final List<GNEsportLeagueStat> participants;
  final Map<String, GNUser> usersById;
  final bool isMember;
  final Set<String> pendingMatchIds;
  final Map<String, String> matchErrorsById;
  final DetailSliceStatus matchesSliceStatus;
  final String? matchesError;
  final int refreshTick;
  final String? leagueId;

  _MatchesViewData.fromState(TournamentDetailState state)
    : matches = List.unmodifiable(state.matches),
      matchRenderData = List.unmodifiable(
        state.matches.map(
          (match) => List<Object?>.unmodifiable([
            match,
            match.homeTeam,
            match.awayTeam,
          ]),
        ),
      ),
      participants = List.unmodifiable(state.participants),
      usersById = Map.unmodifiable(state.usersById),
      isMember = state.currentUserIsMember,
      pendingMatchIds = Set.unmodifiable(state.pendingMatchIds),
      matchErrorsById = Map.unmodifiable(state.matchErrorsById),
      matchesSliceStatus = state.matchesSliceStatus,
      matchesError = state.streamErrors[TournamentDetailSlice.matches],
      refreshTick = state.refreshTick,
      leagueId = state.league?.id;

  List<GNUser> get users => usersById.values.toList(growable: false);

  @override
  List<Object?> get props => [
    matches,
    matchRenderData,
    participants,
    usersById,
    isMember,
    pendingMatchIds,
    matchErrorsById,
    matchesSliceStatus,
    matchesError,
    refreshTick,
    leagueId,
  ];
}

class _MatchdayHeader extends StatelessWidget {
  final int? matchday;

  const _MatchdayHeader({required this.matchday});

  @override
  Widget build(BuildContext context) {
    final label = matchday == null
        ? context.l10n.tournamentOtherMatches
        : context.l10n.tournamentMatchdayLabel(matchday!);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class EsportMatchesView extends StatefulWidget {
  final bool isFixtures;

  const EsportMatchesView({super.key, required this.isFixtures});

  @override
  State<EsportMatchesView> createState() => _EsportMatchesViewState();
}

class _EsportMatchesViewState extends State<EsportMatchesView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  bool get isFixtures => widget.isFixtures;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      TournamentDetailBloc,
      TournamentDetailState,
      _MatchesViewData
    >(
      selector: _MatchesViewData.fromState,
      builder: (context, data) {
        final allMatches = isFixtures
            ? data.matches
                  .where(
                    (match) => !match.isFinished && match.phase != 'knockout',
                  )
                  .toList()
            : data.matches.where((match) => match.isFinished).toList();
        final matches = isFixtures
            ? allMatches
            : _filterByPlayerNames(allMatches, _searchQuery);
        final showActions =
            isFixtures && data.isMember && data.participants.length > 1;

        return Column(
          children: [
            if (showActions)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.tournamentScheduleTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: context.l10n.tournamentCreateCustomMatchTooltip,
                      // coverage:ignore-start
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (cxt) => CreateCustomMatchDialog(
                            users: data.users,
                            onMatchCreated: (home, away) {
                              context.read<TournamentDetailBloc>().add(
                                CreateCustomMatch(
                                  homeTeam: home,
                                  awayTeam: away,
                                ),
                              );
                              Navigator.of(context).pop();
                            },
                          ),
                        );
                      },
                      // coverage:ignore-end
                    ),
                    FilledButton.tonal(
                      onPressed: () =>
                          _confirmGenerateRound(context, allMatches.length),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(context.l10n.tournamentAddRound),
                    ),
                  ],
                ),
              ),
            if (!isFixtures && allMatches.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: context.l10n.tournamentSearchPlayerHint,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.28),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.28),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
              ),
            if (data.matchesSliceStatus == DetailSliceStatus.failed)
              _buildMatchesError(context, data.matchesError),
            Expanded(
              child: KeyedSubtree(
                key: const Key('tournament-match-list'),
                child: _buildMatchList(context, matches, data),
              ),
            ),
          ],
        );
      },
    );
  }

  List<GNEsportMatch> _filterByPlayerNames(
    List<GNEsportMatch> matches,
    String query,
  ) {
    final tokens = removeVietnameseDiacritics(
      query,
    ).split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return matches;

    return matches.where((match) {
      final home = removeVietnameseDiacritics(
        match.homeTeam?.displayName ?? '',
      );
      final away = removeVietnameseDiacritics(
        match.awayTeam?.displayName ?? '',
      );
      return tokens.every((t) => home.contains(t) || away.contains(t));
    }).toList();
  }

  Future<void> _refresh(
    BuildContext context,
    String? leagueId,
    int refreshTick,
  ) async {
    final bloc = context.read<TournamentDetailBloc>();
    if (leagueId == null) return;
    final refreshed = bloc.stream.firstWhere(
      (state) => state.refreshTick > refreshTick,
    );
    bloc.add(EnsureDetailSubscriptions(leagueId));
    await refreshed;
  }

  Widget _buildMatchesError(BuildContext context, String? message) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          if (message != null && message.trim().isNotEmpty)
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            )
          else
            const Spacer(),
          TextButton(
            onPressed: () => context.read<TournamentDetailBloc>().add(
              const RetryDetailSlice(TournamentDetailSlice.matches),
            ),
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchList(
    BuildContext context,
    List<GNEsportMatch> matches,
    _MatchesViewData data,
  ) {
    if (matches.isEmpty) {
      final empty = !isFixtures && _searchQuery.isNotEmpty
          ? AppEmptyState(
              icon: Icons.search_off,
              title: context.l10n.tournamentNoMatchesFound,
            )
          : AppEmptyState(
              icon: isFixtures
                  ? Icons.calendar_today_outlined
                  : Icons.scoreboard_outlined,
              title: isFixtures
                  ? context.l10n.tournamentNoFixtures
                  : context.l10n.tournamentNoResults, // coverage:ignore-line
            );
      return RefreshIndicator(
        onRefresh: () => _refresh(context, data.leagueId, data.refreshTick),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: 400, child: empty)],
        ),
      );
    }

    // Fixtures are organised into matchdays; results stay a flat list so the
    // name search keeps behaving like a plain filter.
    final rows = isFixtures
        ? _flatten(groupFixturesByMatchday(matches))
        : matches.map(_MatchRow.new).toList();

    return RefreshIndicator(
      onRefresh: () => _refresh(context, data.leagueId, data.refreshTick),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final row = rows[index];
            if (row is _HeaderRow) {
              return _MatchdayHeader(matchday: row.matchday);
            }
            final match = (row as _MatchRow).match;
            final isPending = data.pendingMatchIds.contains(match.id);
            return Slidable(
              endActionPane: ActionPane(
                motion: const StretchMotion(),
                children: [
                  if (data.isMember)
                    SlidableAction(
                      borderRadius: BorderRadius.circular(16),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      icon: Icons.delete_outline,
                      // coverage:ignore-start
                      onPressed: isPending
                          ? null
                          : (context) {
                              context.read<TournamentDetailBloc>().add(
                                DeleteEsportMatch(match),
                              );
                            },
                      // coverage:ignore-end
                    ),
                ],
              ),
              child: EsportMatchItem(
                match: match,
                isPending: isPending,
                errorMessage: data.matchErrorsById[match.id],
                onTap: isFixtures && data.isMember && !isPending
                    ? () => showUpdateMatchScoreDialog(context, match)
                    : null,
                // coverage:ignore-start
                onLongPress: !isFixtures && data.isMember && !isPending
                    ? () => showUpdateMatchScoreDialog(context, match)
                    : null,
                // coverage:ignore-end
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemCount: rows.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  List<_FixtureRow> _flatten(List<FixtureSection> sections) {
    return [
      for (final section in sections) ...[
        _HeaderRow(section.matchday),
        ...section.matches.map(_MatchRow.new),
      ],
    ];
  }

  Future<void> _confirmGenerateRound(
    BuildContext context,
    int existingCount,
  ) async {
    // coverage:ignore-start
    final message = existingCount > 0
        ? context.l10n.tournamentGenerateRoundWithExisting(existingCount)
        : context.l10n.tournamentGenerateRoundMessage;
    // coverage:ignore-end
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: context.l10n.tournamentAddRound,
      message: message,
      confirmText: context.l10n.commonCreate,
    );
    if (confirmed == true && context.mounted) {
      context.read<TournamentDetailBloc>().add(const GenerateRound());
    }
  }
}
