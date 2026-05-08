import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
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
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.28),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lịch thi đấu',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      tooltip: 'Tạo trận tùy chỉnh',
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
                    ),
                    FilledButton.tonal(
                      onPressed: () => _confirmGenerateRound(context, state.fixtures.length),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Tạo vòng đấu'),
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
                    hintText: 'Tìm theo tên người chơi (vd: A B)',
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
                    fillColor: Theme.of(context).colorScheme.surface,
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
          ? const AppEmptyState(
              icon: Icons.search_off,
              title: 'Không tìm thấy trận nào',
            )
          : AppEmptyState(
              icon: isFixtures
                  ? Icons.calendar_today_outlined
                  : Icons.scoreboard_outlined,
              title: isFixtures ? 'Chưa có lịch thi đấu' : 'Chưa có kết quả',
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
                      onPressed: (context) {
                        context.read<TournamentDetailBloc>().add(
                          DeleteEsportMatch(match),
                        );
                      },
                    ),
                ],
              ),
              child: EsportMatchItem(
                match: match,
                onTap: isFixtures && state.currentUserIsMember
                    ? () => showUpdateMatchScoreDialog(context, match)
                    : null,
                onLongPress: !isFixtures && state.currentUserIsMember
                    ? () => showUpdateMatchScoreDialog(context, match)
                    : null,
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

  Future<void> _confirmGenerateRound(BuildContext context, int existingCount) async {
    final message = existingCount > 0
        ? 'Hiện có $existingCount trận trong lịch. Tạo thêm một vòng mới?'
        : 'Tạo vòng đấu round-robin cho tất cả người chơi?';
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Tạo vòng đấu',
      message: message,
      confirmText: 'Tạo',
    );
    if (confirmed == true && context.mounted) {
      context.read<TournamentDetailBloc>().add(const GenerateRound());
    }
  }

}
