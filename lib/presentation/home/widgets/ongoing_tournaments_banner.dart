import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_item.dart';
import 'package:pes_arena/presentation/home/ongoing_tournaments/bloc/ongoing_tournaments_bloc.dart';
import 'package:pes_arena/routing.dart';

class OngoingTournamentsBanner extends StatelessWidget {
  const OngoingTournamentsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OngoingTournamentsBloc, OngoingTournamentsState>(
      buildWhen: (prev, curr) => prev.leagues != curr.leagues,
      builder: (context, state) {
        final ongoing = _filterOngoing(state.leagues, DateTime.now());
        if (ongoing.isEmpty) return const SizedBox.shrink();
        return _Banner(leagues: ongoing);
      },
    );
  }
}

@visibleForTesting
List<GNEsportLeague> filterOngoingLeagues(
  List<GNEsportLeague> leagues,
  DateTime now,
) => _filterOngoing(leagues, now);

List<GNEsportLeague> _filterOngoing(
  List<GNEsportLeague> leagues,
  DateTime now,
) {
  final today = DateTime(now.year, now.month, now.day);
  return leagues.where((l) {
    final start = DateTime(l.startDate.year, l.startDate.month, l.startDate.day);
    final endRaw = l.endDate ?? l.startDate;
    final end = DateTime(endRaw.year, endRaw.month, endRaw.day);
    return !today.isBefore(start) && !today.isAfter(end);
  }).toList();
}

class _Banner extends StatelessWidget {
  final List<GNEsportLeague> leagues;

  const _Banner({required this.leagues});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Giải đấu đang diễn ra',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...leagues.map(
            (l) => TournamentItem(
              league: l,
              onTap: () => context.push(Routing.tournamentDetailPath(l.id)),
            ),
          ),
        ],
      ),
    );
  }
}
