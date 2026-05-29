import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/l10n/l10n.dart';
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
        final ongoing = _filterOngoing(state.leagues);
        if (ongoing.isEmpty) return const SizedBox.shrink();
        return _Banner(leagues: ongoing);
      },
    );
  }
}

@visibleForTesting
List<GNEsportLeague> filterOngoingLeagues(List<GNEsportLeague> leagues) =>
    _filterOngoing(leagues);

// Filter by admin-managed `status == ongoing` to match the "Live" badge on
// the tournament list. Date-range filtering used to live here and let
// finished leagues leak through whenever `endDate` was still in the future
// or unset — status is the source of truth admins actually edit.
List<GNEsportLeague> _filterOngoing(List<GNEsportLeague> leagues) {
  return leagues
      .where(
        (l) =>
            GNEsportLeagueStatusExtension.fromString(l.status) ==
            GNEsportLeagueStatus.ongoing,
      )
      .toList();
}

class _Banner extends StatelessWidget {
  final List<GNEsportLeague> leagues;

  const _Banner({required this.leagues});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.homeOngoingTournamentsTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${leagues.length}',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
