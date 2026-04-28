import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/presentation/esport/tournament/bloc/tournament_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_item.dart';
import 'package:pes_arena/presentation/notification/bloc/notification_bloc.dart';

import '../../../routing.dart';
import '../groups/bloc/group_bloc.dart';
import 'create_esport_league_page.dart';

class TournamentView extends StatelessWidget {
  const TournamentView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<TournamentBloc, TournamentState>(
      builder: (context, state) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            centerTitle: false,
            title: Row(
              spacing: 4,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset('assets/images/pes.jpg', height: 32),
                ),
                Expanded(
                  child: TabBar(
                    padding: EdgeInsets.zero,
                    dividerColor: Colors.transparent,
                    tabAlignment: TabAlignment.start,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Giải đấu của tôi'),
                      Tab(text: 'Giải đấu khác'),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) => IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications_outlined),
                      if (state.unreadNotificationsCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            width: 8,
                            height: 8,
                          ),
                        ),
                    ],
                  ),
                  onPressed: () =>
                      Navigator.pushNamed(context, Routing.notification),
                ),
              ),
            ],
          ),
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _MyLeaguesTab(state: state),
              _OtherLeaguesTab(state: state),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _onCreateTournamentPressed(context),
            label: const Text('Tạo giải đấu'),
            icon: const Icon(Icons.add),
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

  void _onCreateTournamentPressed(BuildContext context) {
    final groups = context.read<GroupBloc>().state.userGroups;
    if (groups.isEmpty) {
      showToast('Bạn chưa tham gia nhóm nào. Hãy tham gia nhóm trước');
      return;
    }
    final tournamentBloc = context.read<TournamentBloc>();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => CreateEsportLeaguePage(
          groups: groups,
          onAddLeague: (
            name,
            groupId,
            startDate,
            endDate,
            description,
            rankPayoutEnabled,
            rankPayouts,
            defaultMatchCost,
          ) {
            tournamentBloc.add(
              AddTournament(
                name: name,
                groupId: groupId,
                startDate: startDate,
                endDate: endDate,
                description: description,
                rankPayoutEnabled: rankPayoutEnabled,
                rankPayouts: rankPayouts,
                defaultMatchCost: defaultMatchCost,
              ),
            );
            Navigator.of(ctx).pop();
          },
        ),
      ),
    );
  }
}

class _MyLeaguesTab extends StatelessWidget {
  final TournamentState state;
  const _MyLeaguesTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => _refresh(context),
      child: state.myLeagues.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                if (state.myStatus.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  const SizedBox(
                    height: 400,
                    child: AppEmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: 'Không có giải đấu nào',
                      subtitle: 'Tạo giải đấu mới để bắt đầu',
                    ),
                  ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: state.myLeagues.length,
              itemBuilder: (context, index) =>
                  _leagueTile(context, state.myLeagues[index]),
            ),
    );
  }

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<TournamentBloc>();
    final tickBefore = bloc.state.refreshTick;
    bloc.add(RefreshTournaments());
    await bloc.stream.firstWhere(
      (s) => s.refreshTick > tickBefore,
    );
  }

  Widget _leagueTile(BuildContext context, GNEsportLeague league) {
    return TournamentItem(
      league: league,
      onTap: () async {
        await Navigator.of(context).pushNamed(
          Routing.tournamentDetail,
          arguments: league.id,
        );
        // Returning from the detail page may have changed the league
        // (status, name, participants) — refresh the "my" list silently.
        if (context.mounted) {
          context.read<TournamentBloc>().add(LoadMyLeagues());
        }
      },
    );
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
    await bloc.stream.firstWhere(
      (s) => s.refreshTick > tickBefore,
    );
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
              children: [
                if (state.otherStatus.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else
                  const SizedBox(
                    height: 400,
                    child: AppEmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: 'Không có giải đấu nào',
                    ),
                  ),
              ],
            )
          : ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              // +1 footer slot for the loading spinner / end-of-list marker.
              itemCount: state.otherLeagues.length + 1,
              itemBuilder: (context, index) {
                if (index == state.otherLeagues.length) {
                  return _footer(state);
                }
                return TournamentItem(
                  league: state.otherLeagues[index],
                  onTap: () => Navigator.of(context).pushNamed(
                    Routing.tournamentDetail,
                    arguments: state.otherLeagues[index].id,
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
              color: Theme.of(context).colorScheme.onSurface.withValues(
                alpha: 0.4,
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox(height: 16);
  }
}
