import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/presentation/esport/tournament/bloc/tournament_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_item.dart';

import '../../../routing.dart';
import '../groups/bloc/group_bloc.dart';
import 'create_esport_league_page.dart';

typedef TournamentCreatePageBuilder =
    Widget Function({
      required List<GNEsportGroup> groups,
      required OnAddLeagueCallback onAddLeague,
    });

/// Injectable for tests to avoid depending on the full wizard flow.
TournamentCreatePageBuilder tournamentCreatePageBuilder =
    _defaultCreatePageBuilder;

// coverage:ignore-start
Widget _defaultCreatePageBuilder({
  required List<GNEsportGroup> groups,
  required OnAddLeagueCallback onAddLeague,
}) {
  return CreateEsportLeaguePage(groups: groups, onAddLeague: onAddLeague);
}
// coverage:ignore-end

class TournamentView extends StatelessWidget {
  const TournamentView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TournamentBloc, TournamentState>(
      builder: (context, state) => DefaultTabController(
        length: 3,
        child: Scaffold(
          body: _TournamentBody(
            state: state,
            onCreatePressed: () => openCreateTournament(context),
          ),
        ),
      ),
      listener: (context, state) {
        if (state.errorMessage.isNotEmpty) {
          showToast(state.errorMessage);
        }
      },
    );
  }
}

class _TournamentBody extends StatelessWidget {
  final TournamentState state;
  final VoidCallback onCreatePressed;

  const _TournamentBody({required this.state, required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      child: SafeArea(
        child: Column(
          children: [
            _TournamentHero(state: state, onCreatePressed: onCreatePressed),
            const _TournamentTabBar(),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MyLeaguesTab(state: state),
                  _ManagedLeaguesTab(state: state),
                  _OtherLeaguesTab(state: state),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TournamentHero extends StatelessWidget {
  final TournamentState state;
  final VoidCallback onCreatePressed;

  const _TournamentHero({required this.state, required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final allLeagues = [...state.myLeagues, ...state.otherLeagues];
    final ongoingCount = allLeagues
        .where(
          (league) =>
              GNEsportLeagueStatusExtension.fromString(league.status) ==
              GNEsportLeagueStatus.ongoing,
        )
        .length;
    final participantCount = {
      for (final league in allLeagues) ...league.participants,
    }.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 24,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.tournamentHeroEyebrow,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.tournamentHeroTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onCreatePressed,
                icon: const Icon(Icons.add, size: 18),
                label: Text(context.l10n.tournamentCreateButton),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: context.l10n.tournamentMyStat,
                  value: state.myHasMore
                      ? '${state.myLeagues.length}+'
                      : '${state.myLeagues.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: context.l10n.tournamentLiveStat,
                  value: '$ongoingCount',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: context.l10n.tournamentPlayersStat,
                  value: '$participantCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentTabBar extends StatelessWidget {
  const _TournamentTabBar();

  @override
  Widget build(BuildContext context) {
    final tabController = DefaultTabController.of(context);

    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: AnimatedBuilder(
        animation: tabController.animation!,
        builder: (context, _) {
          final selectedIndex = tabController.index;

          return Row(
            children: [
              Expanded(
                child: _TournamentTabOption(
                  label: context.l10n.tournamentJoinedTab,
                  selected: selectedIndex == 0,
                  colorScheme: colorScheme,
                  theme: theme,
                  onTap: () => tabController.animateTo(0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TournamentTabOption(
                  label: context.l10n.tournamentManagedTab,
                  selected: selectedIndex == 1,
                  colorScheme: colorScheme,
                  theme: theme,
                  onTap: () => tabController.animateTo(1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TournamentTabOption(
                  label: context.l10n.tournamentOtherTab,
                  selected: selectedIndex == 2,
                  colorScheme: colorScheme,
                  theme: theme,
                  onTap: () => tabController.animateTo(2),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TournamentTabOption extends StatelessWidget {
  final String label;
  final bool selected;
  final ThemeData theme;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _TournamentTabOption({
    required this.label,
    required this.selected,
    required this.colorScheme,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.only(top: 8, bottom: 7),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 22 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> openCreateTournament(BuildContext context) async {
  final groups = context.read<GroupBloc>().state.userGroups;
  if (groups.isEmpty) {
    showToast(context.l10n.tournamentJoinGroupFirst);
    return;
  }
  final tournamentBloc = context.read<TournamentBloc>();
  final repo = GetIt.instance<EsportLeagueRepository>();
  final createSuccessMessage = context.l10n.tournamentCreateSuccess;

  final leagueId = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (ctx) => tournamentCreatePageBuilder(
        groups: groups,
        onAddLeague:
            ({
              required name,
              required groupId,
              startDate,
              endDate,
              required description,
              required rankPayoutEnabled,
              required rankPayouts,
              required defaultMatchCost,
              required defaultPerGoalEnabled,
              required defaultCostPerGoal,
              required mode,
              required participants,
              required groupCount,
              required advanceCount,
              required knockoutSeeding,
              required groupAssignment,
            }) async {
              final id = await repo.addLeague(
                name: name,
                groupId: groupId,
                startDate: startDate,
                endDate: endDate,
                description: description,
                rankPayoutEnabled: rankPayoutEnabled,
                rankPayouts: rankPayouts,
                defaultMatchCost: defaultMatchCost,
                defaultPerGoalEnabled: defaultPerGoalEnabled,
                defaultCostPerGoal: defaultCostPerGoal,
                mode: mode,
                groupCount: groupCount,
                advanceCount: advanceCount,
                participants: participants,
                knockoutSeeding: knockoutSeeding,
              );
              try {
                if (participants.length >= 2) {
                  switch (mode) {
                    case TournamentMode.league:
                      await repo.generateRound(
                        leagueId: id,
                        teamIds: participants,
                      );
                    case TournamentMode.cup:
                      await repo.generateCupBracket(
                        leagueId: id,
                        seededTeamIds: participants,
                      );
                    case TournamentMode.full:
                      final groups = List.generate(
                        groupCount,
                        (_) => <String>[],
                      );
                      for (final entry in groupAssignment.entries) {
                        if (entry.value < groups.length) {
                          groups[entry.value].add(entry.key);
                        }
                      }
                      await repo.generateFullTournament(
                        leagueId: id,
                        groups: groups,
                        advanceCount: advanceCount,
                        knockoutSeeding: knockoutSeeding,
                      );
                  }
                }
              } catch (createError, createStack) {
                // Roll back the league document so no zombie league is left behind.
                try {
                  await repo.deleteLeague(id);
                } catch (rollbackError, rollbackStack) {
                  debugPrint(
                    'League create rollback failed: $rollbackError\n$rollbackStack',
                  );
                }
                Error.throwWithStackTrace(createError, createStack);
              }
              return id;
            },
      ),
    ),
  );

  if (leagueId == null || !context.mounted) return;
  showToast(createSuccessMessage);
  try {
    await context.push(Routing.tournamentDetailPath(leagueId));
  } finally {
    tournamentBloc.add(LoadMyLeagues());
    tournamentBloc.add(LoadManagedLeagues());
  }
}

class _MyLeaguesTab extends StatefulWidget {
  final TournamentState state;
  const _MyLeaguesTab({required this.state});

  @override
  State<_MyLeaguesTab> createState() => _MyLeaguesTabState();
}

class _MyLeaguesTabState extends State<_MyLeaguesTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      final state = context.read<TournamentBloc>().state;
      if (state.myHasMore && state.myStatus != ViewStatus.loading) {
        context.read<TournamentBloc>().add(LoadMoreMyLeagues());
      }
    }
  }

  Future<void> _refresh() async {
    final bloc = context.read<TournamentBloc>();
    final tickBefore = bloc.state.refreshTick;
    bloc.add(RefreshTournaments());
    await bloc.stream.firstWhere((s) => s.refreshTick > tickBefore);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: state.myLeagues.isEmpty
          ? ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 96),
              children: [
                if (state.myStatus.isLoading)
                  const _TournamentLoadingCard()
                else
                  _TournamentEmptyState(
                    title: context.l10n.tournamentEmptyTitle,
                    subtitle: context.l10n.tournamentEmptySubtitle,
                  ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 96),
              itemCount: state.myLeagues.length + 1,
              itemBuilder: (context, index) {
                if (index == state.myLeagues.length) {
                  return _footer(state);
                }
                final league = state.myLeagues[index];
                return TournamentItem(
                  league: league,
                  onTap: () async {
                    await context.push(Routing.tournamentDetailPath(league.id));
                    if (context.mounted) {
                      context.read<TournamentBloc>().add(LoadMyLeagues());
                    }
                  },
                );
              },
            ),
    );
  }

  Widget _footer(TournamentState state) {
    if (state.myStatus.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (!state.myHasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            context.l10n.commonListEnd,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}

class _ManagedLeaguesTab extends StatefulWidget {
  final TournamentState state;
  const _ManagedLeaguesTab({required this.state});

  @override
  State<_ManagedLeaguesTab> createState() => _ManagedLeaguesTabState();
}

class _ManagedLeaguesTabState extends State<_ManagedLeaguesTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      final state = context.read<TournamentBloc>().state;
      if (state.managedHasMore && state.managedStatus != ViewStatus.loading) {
        context.read<TournamentBloc>().add(LoadMoreManagedLeagues());
      }
    }
  }

  Future<void> _refresh() async {
    final bloc = context.read<TournamentBloc>();
    final tickBefore = bloc.state.refreshTick;
    bloc.add(RefreshTournaments());
    await bloc.stream.firstWhere((s) => s.refreshTick > tickBefore);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: state.managedLeagues.isEmpty
          // coverage:ignore-start
          ? ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 96),
              children: [
                if (state.managedStatus.isLoading)
                  const _TournamentLoadingCard()
                else
                  _TournamentEmptyState(
                    title: context.l10n.tournamentEmptyTitle,
                    subtitle: context.l10n.tournamentManagedEmptySubtitle,
                  ),
              ],
            )
          // coverage:ignore-end
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 96),
              itemCount: state.managedLeagues.length + 1,
              itemBuilder: (context, index) {
                if (index == state.managedLeagues.length) {
                  return _footer(state);
                }
                final league = state.managedLeagues[index];
                return TournamentItem(
                  league: league,
                  onTap: () async {
                    await context.push(Routing.tournamentDetailPath(league.id));
                    if (context.mounted) {
                      context.read<TournamentBloc>().add(LoadManagedLeagues());
                    }
                  },
                );
              },
            ),
    );
  }

  Widget _footer(TournamentState state) {
    if (state.managedStatus.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (!state.managedHasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            context.l10n.commonListEnd,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}

class _OtherLeaguesTab extends StatefulWidget {
  final TournamentState state;
  const _OtherLeaguesTab({required this.state});

  @override
  State<_OtherLeaguesTab> createState() => _OtherLeaguesTabState();
}

class _OtherLeaguesTabState extends State<_OtherLeaguesTab> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    // Trigger load-more when within 400px of the bottom — gives the next
    // page time to land before the user actually hits the end.
    if (pos.pixels >= pos.maxScrollExtent - 400) {
      final state = context.read<TournamentBloc>().state;
      if (state.otherHasMore && state.otherStatus != ViewStatus.loading) {
        context.read<TournamentBloc>().add(LoadMoreOtherLeagues());
      }
    }
  }

  Future<void> _refresh() async {
    final bloc = context.read<TournamentBloc>();
    final tickBefore = bloc.state.refreshTick;
    bloc.add(RefreshTournaments());
    await bloc.stream.firstWhere((s) => s.refreshTick > tickBefore);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: state.otherLeagues.isEmpty
          // coverage:ignore-start
          ? ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 96),
              children: [
                if (state.otherStatus.isLoading)
                  const _TournamentLoadingCard()
                else
                  _TournamentEmptyState(
                    title: context.l10n.tournamentEmptyTitle,
                  ),
              ],
            )
          // coverage:ignore-end
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 96),
              // +1 footer slot for the loading spinner / end-of-list marker.
              itemCount: state.otherLeagues.length + 1,
              itemBuilder: (context, index) {
                if (index == state.otherLeagues.length) {
                  return _footer(state);
                }
                return TournamentItem(
                  league: state.otherLeagues[index],
                  onTap: () => context.push(
                    Routing.tournamentDetailPath(state.otherLeagues[index].id),
                  ),
                );
              },
            ),
    );
  }

  Widget _footer(TournamentState state) {
    if (state.otherStatus.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (!state.otherHasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            context.l10n.commonListEnd,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}

class _TournamentLoadingCard extends StatelessWidget {
  const _TournamentLoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 24, left: 22, right: 22, bottom: 22),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _TournamentEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _TournamentEmptyState({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24, left: 22, right: 22, bottom: 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 40,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
