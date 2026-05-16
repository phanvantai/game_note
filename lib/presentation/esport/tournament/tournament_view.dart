import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/presentation/esport/tournament/bloc/tournament_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_item.dart';

import '../../../routing.dart';
import '../groups/bloc/group_bloc.dart';
import 'create_esport_league_page.dart';

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.secondary.withValues(alpha: 0.16),
            theme.scaffoldBackgroundColor,
            colorScheme.primary.withValues(alpha: 0.06),
          ],
          stops: const [0, 0.46, 1],
        ),
      ),
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

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.26),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.emoji_events_outlined,
                  color: colorScheme.onSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tournament arena',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quản lý giải đấu PES',
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
                label: const Text('Tạo giải đấu'),
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
                  label: 'Của tôi',
                  value: state.myHasMore
                      ? '${state.myLeagues.length}+'
                      : '${state.myLeagues.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(label: 'Live', value: '$ongoingCount'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: 'Player',
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
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(12),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 46,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.42)),
      ),
      child: TabBar(
        padding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: colorScheme.onSecondary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        tabs: const [
          Tab(text: 'Tham gia'),
          Tab(text: 'Quản lý'),
          Tab(text: 'Khác'),
        ],
      ),
    );
  }
}

Future<void> openCreateTournament(BuildContext context) async {
  final groups = context.read<GroupBloc>().state.userGroups;
  if (groups.isEmpty) {
    showToast('Bạn chưa tham gia nhóm nào. Hãy tham gia nhóm trước');
    return;
  }
  final tournamentBloc = context.read<TournamentBloc>();
  final repo = GetIt.instance<EsportLeagueRepository>();

  final leagueId = await Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (ctx) => CreateEsportLeaguePage(
        groups: groups,
        onAddLeague: ({
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
            if (participants.isNotEmpty) {
              await repo.addMultipleParticipants(
                leagueId: id,
                userIds: participants,
              );
            }
            if (participants.length >= 2) {
              switch (mode) {
                case TournamentMode.league:
                  await repo.generateRound(leagueId: id, teamIds: participants);
                case TournamentMode.cup:
                  await repo.generateCupBracket(leagueId: id, seededTeamIds: participants);
                case TournamentMode.full:
                  final groups = List.generate(groupCount, (_) => <String>[]);
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
          } catch (e) {
            // Roll back the league document so no zombie league is left behind.
            await repo.deleteLeague(id);
            rethrow;
          }
          tournamentBloc.add(LoadMyLeagues());
          tournamentBloc.add(LoadManagedLeagues());
          showToast('Tạo giải đấu thành công');
          return id;
        },
      ),
    ),
  );

  if (leagueId != null && context.mounted) {
    context.push(Routing.tournamentDetailPath(leagueId));
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
                  const _TournamentEmptyState(
                    title: 'Không có giải đấu nào',
                    subtitle: 'Tạo giải đấu mới để bắt đầu',
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
            'Đã hết',
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
          ? ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 96),
              children: [
                if (state.managedStatus.isLoading)
                  const _TournamentLoadingCard()
                else
                  const _TournamentEmptyState(
                    title: 'Chưa có giải đấu nào',
                    subtitle: 'Tạo giải đấu mới để bắt đầu quản lý',
                  ),
              ],
            )
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
                      context
                          .read<TournamentBloc>()
                          .add(LoadManagedLeagues());
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
            'Đã hết',
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
          ? ListView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 96),
              children: [
                if (state.otherStatus.isLoading)
                  const _TournamentLoadingCard()
                else
                  const _TournamentEmptyState(title: 'Không có giải đấu nào'),
              ],
            )
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
            'Đã hết',
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.45)),
      ),
      child: const Center(child: CircularProgressIndicator()),
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
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(
              Icons.emoji_events_outlined,
              color: colorScheme.secondary,
              size: 30,
            ),
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
