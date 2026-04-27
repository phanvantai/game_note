import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/create_custom_match_dialog.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_team.dart';

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
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    const Spacer(),
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
                      onPressed: () {
                        context.read<TournamentDetailBloc>().add(
                          const GenerateRound(),
                        );
                      },
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
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      setState(() => _searchQuery = value),
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
                    fillColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
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
    final tokens = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    if (tokens.isEmpty) return matches;

    return matches.where((match) {
      final home = (match.homeTeam?.displayName ?? '').toLowerCase();
      final away = (match.awayTeam?.displayName ?? '').toLowerCase();
      return tokens.every((t) => home.contains(t) || away.contains(t));
    }).toList();
  }

  Widget _buildMatchList(
    BuildContext context,
    List<GNEsportMatch> matches,
    TournamentDetailState state,
  ) {
    if (matches.isEmpty) {
      if (!isFixtures && _searchQuery.isNotEmpty) {
        return const AppEmptyState(
          icon: Icons.search_off,
          title: 'Không tìm thấy trận nào',
        );
      }
      return AppEmptyState(
        icon: isFixtures
            ? Icons.calendar_today_outlined
            : Icons.scoreboard_outlined,
        title: isFixtures ? 'Chưa có lịch thi đấu' : 'Chưa có kết quả',
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView.separated(
        itemBuilder: (context, index) {
          final match = matches[index];
          return Slidable(
            endActionPane: ActionPane(
              motion: const StretchMotion(),
              children: [
                if (state.currentUserIsMember)
                  SlidableAction(
                    borderRadius: BorderRadius.circular(12),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    icon: Icons.delete_outline,
                    onPressed: (context) {
                      context.read<TournamentDetailBloc>().add(
                        DeleteEsportMatch(match),
                      );
                    },
                  ),
                if (state.currentUserIsMember)
                  SlidableAction(
                    borderRadius: BorderRadius.circular(12),
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    icon: Icons.monetization_on_outlined,
                    onPressed: (ctx) => _showMedalDialog(context, match),
                  ),
              ],
            ),
            child: EsportMatchItem(
              match: match,
              onTap: isFixtures && state.currentUserIsMember
                  ? () => _updateMatchDialog(context, match)
                  : null,
              onLongPress: !isFixtures && state.currentUserIsMember
                  ? () => _updateMatchDialog(context, match)
                  : null,
            ),
          );
        },
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemCount: matches.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  void _showMedalDialog(BuildContext context, GNEsportMatch match) {
    final medalController = TextEditingController()
      ..text = match.medals.toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Số lượng medal'),
        content: TextField(
          controller: medalController,
          keyboardType: TextInputType.number,
          decoration: appInputDecoration(
            context: context,
            hintText: 'Nhập số lượng',
            prefixIcon: Icons.monetization_on_outlined,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              final medal = int.tryParse(medalController.text);
              if (medal == null) {
                showToast('Nhập số lượng medal', gravity: ToastGravity.TOP);
                return;
              }
              context.read<TournamentDetailBloc>().add(
                UpdateMatchMedals(match.id, medal),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _updateMatchDialog(BuildContext context, GNEsportMatch match) {
    final homeScoreController = TextEditingController();
    final awayScoreController = TextEditingController();
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật kết quả'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (match.homeTeam != null)
              Row(
                children: [
                  Expanded(child: EsportMatchTeam(user: match.homeTeam!)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: TextField(
                      controller: homeScoreController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            if (match.awayTeam != null)
              Row(
                children: [
                  Expanded(child: EsportMatchTeam(user: match.awayTeam!)),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 56,
                    child: TextField(
                      controller: awayScoreController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              if (homeScoreController.text.isEmpty ||
                  awayScoreController.text.isEmpty) {
                showToast('Nhập kết quả trận đấu', gravity: ToastGravity.TOP);
                return;
              }
              final homeScore = int.parse(homeScoreController.text);
              final awayScore = int.parse(awayScoreController.text);
              context.read<TournamentDetailBloc>().add(
                UpdateEsportMatch(
                  match.copyWith(homeScore: homeScore, awayScore: awayScore),
                ),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }
}
