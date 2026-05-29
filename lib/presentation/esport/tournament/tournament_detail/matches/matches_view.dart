import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/create_custom_match_dialog.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/update_match_score_dialog.dart';

import '../bloc/tournament_detail_bloc.dart';

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
    return BlocBuilder<TournamentDetailBloc, TournamentDetailState>(
      builder: (context, state) {
        final allMatches = isFixtures ? state.fixtures : state.results;
        final matches = isFixtures
            ? allMatches
            : _filterByPlayerNames(allMatches, _searchQuery);
        final showActions =
            isFixtures &&
            state.currentUserIsMember &&
            state.participants.length > 1;

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
                            users: state.users,
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
                          _confirmGenerateRound(context, state.fixtures.length),
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
            if (!isFixtures && state.results.isNotEmpty)
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
            Expanded(child: _buildMatchList(context, matches, state)),
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

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<TournamentDetailBloc>();
    final leagueId = bloc.state.league?.id;
    if (leagueId == null) return;
    final tickBefore = bloc.state.refreshTick;
    bloc.add(GetParticipantsAndMatches(leagueId));
    await bloc.stream.firstWhere((s) => s.refreshTick > tickBefore);
  }

  Widget _buildMatchList(
    BuildContext context,
    List<GNEsportMatch> matches,
    TournamentDetailState state,
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
        onRefresh: () => _refresh(context),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: 400, child: empty)],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final match = matches[index];
            return Slidable(
              endActionPane: ActionPane(
                motion: const StretchMotion(),
                children: [
                  if (state.currentUserIsMember)
                    SlidableAction(
                      borderRadius: BorderRadius.circular(16),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      icon: Icons.delete_outline,
                      // coverage:ignore-start
                      onPressed: (context) {
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
                onTap: isFixtures && state.currentUserIsMember
                    ? () => showUpdateMatchScoreDialog(context, match)
                    : null,
                // coverage:ignore-start
                onLongPress: !isFixtures && state.currentUserIsMember
                    ? () => showUpdateMatchScoreDialog(context, match)
                    : null,
                // coverage:ignore-end
              ),
            );
          },
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemCount: matches.length,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
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
