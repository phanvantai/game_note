import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/l10n/l10n.dart';
import '../../cost/collapsible_cost_config.dart';
import '../../cost/cost_config_form.dart';
import '../../cost/cost_summary_panel.dart';
import '../bloc/tournament_detail_bloc.dart';

class _CostViewData extends Equatable {
  final GNEsportLeague? league;
  final List<GNEsportLeagueStat> participants;
  final List<GNEsportMatch> costMatches;
  final List<GNEsportMatch> knockoutMatches;
  final bool isAdmin;
  final DetailSliceStatus statsSliceStatus;
  final DetailSliceStatus matchesSliceStatus;
  final String? statsError;
  final String? matchesError;
  final int refreshTick;

  final List<int> _rankPayouts;
  final List<String> _leagueParticipants;
  final List<
    ({
      String homeTeamId,
      String awayTeamId,
      int? homeScore,
      int? awayScore,
      int? matchCost,
      int? costPerGoal,
    })
  >
  _costMatchValues;
  final List<
    ({
      int? knockoutRound,
      bool isFinished,
      String? homeTeamId,
      String? awayTeamId,
      int? homeScore,
      int? awayScore,
      Object? homeTeam,
      Object? awayTeam,
    })
  >
  _knockoutValues;

  _CostViewData.fromState(TournamentDetailState state)
    : league = state.league,
      participants = List.unmodifiable(state.participants),
      costMatches = List.unmodifiable(
        state.matches.where(
          (match) => match.isFinished && (match.matchCost ?? 0) > 0,
        ),
      ),
      knockoutMatches = List.unmodifiable(
        state.matches.where((match) => match.phase == 'knockout'),
      ),
      isAdmin = state.currentUserIsLeagueAdmin,
      statsSliceStatus = state.statsSliceStatus,
      matchesSliceStatus = state.matchesSliceStatus,
      statsError = state.streamErrors[TournamentDetailSlice.stats],
      matchesError = state.streamErrors[TournamentDetailSlice.matches],
      refreshTick = state.refreshTick,
      _rankPayouts = List.unmodifiable(state.league?.rankPayouts ?? const []),
      _leagueParticipants = List.unmodifiable(
        state.league?.participants ?? const [],
      ),
      _costMatchValues = List.unmodifiable(
        state.matches
            .where((match) => match.isFinished && (match.matchCost ?? 0) > 0)
            .map(
              (match) => (
                homeTeamId: match.homeTeamId,
                awayTeamId: match.awayTeamId,
                homeScore: match.homeScore,
                awayScore: match.awayScore,
                matchCost: match.matchCost,
                costPerGoal: match.costPerGoal,
              ),
            ),
      ),
      _knockoutValues = List.unmodifiable(
        state.matches
            .where((match) => match.phase == 'knockout')
            .map(
              (match) => (
                knockoutRound: match.knockoutRound,
                isFinished: match.isFinished,
                homeTeamId: match.isFinished ? match.homeTeamId : null,
                awayTeamId: match.isFinished ? match.awayTeamId : null,
                homeScore: match.isFinished ? match.homeScore : null,
                awayScore: match.isFinished ? match.awayScore : null,
                homeTeam: match.isFinished ? match.homeTeam : null,
                awayTeam: match.isFinished ? match.awayTeam : null,
              ),
            ),
      );

  String? get leagueId => league?.id;

  bool get isBracketMode =>
      league?.mode == TournamentMode.cup || league?.mode == TournamentMode.full;

  @override
  List<Object?> get props => [
    leagueId,
    league?.rankPayoutEnabled,
    _rankPayouts,
    league?.defaultMatchCost,
    league?.defaultPerGoalEnabled,
    league?.defaultCostPerGoal,
    league?.mode,
    league?.status,
    _leagueParticipants,
    isAdmin,
    participants,
    _costMatchValues,
    _knockoutValues,
    statsSliceStatus,
    matchesSliceStatus,
    statsError,
    matchesError,
    refreshTick,
  ];
}

class CostSplitView extends StatelessWidget {
  const CostSplitView({super.key});

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

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
      TournamentDetailBloc,
      TournamentDetailState,
      _CostViewData
    >(
      selector: _CostViewData.fromState,
      builder: (context, data) {
        final league = data.league;
        if (league == null) {
          return RefreshIndicator(
            onRefresh: () => _refresh(context, data.leagueId, data.refreshTick),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 400,
                  child: AppEmptyState(
                    icon: Icons.payments_outlined,
                    title: context.l10n.tournamentLoadingCost,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _refresh(context, data.leagueId, data.refreshTick),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (data.statsSliceStatus == DetailSliceStatus.failed)
                _CostSliceError(
                  message: data.statsError,
                  slice: TournamentDetailSlice.stats,
                ),
              if (data.matchesSliceStatus == DetailSliceStatus.failed)
                _CostSliceError(
                  message: data.matchesError,
                  slice: TournamentDetailSlice.matches,
                ),
              KeyedSubtree(
                key: const Key('league-cost-content'),
                child: Column(
                  children: [
                    if (data.isAdmin) ...[
                      _CostConfigWrapper(
                        key: ValueKey(
                          '${league.id}-${league.rankPayoutEnabled}-${league.rankPayouts.join(',')}-${league.defaultMatchCost}-${league.defaultPerGoalEnabled}-${league.defaultCostPerGoal}',
                        ),
                        league: league,
                        isBracketMode: data.isBracketMode,
                      ),
                      const SizedBox(height: 12),
                    ],
                    CostSummaryPanel(
                      league: league,
                      sortedStats: data.participants,
                      matches: data.costMatches,
                      isBracketMode: data.isBracketMode,
                      knockoutMatches: data.knockoutMatches,
                    ),
                    if (!league.rankPayoutEnabled && data.costMatches.isEmpty)
                      SizedBox(
                        height: 320,
                        child: AppEmptyState(
                          icon: Icons.payments_outlined,
                          title: context.l10n.tournamentNoCostTitle,
                          subtitle: context.l10n.tournamentNoCostSubtitle,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CostSliceError extends StatelessWidget {
  final String? message;
  final TournamentDetailSlice slice;

  const _CostSliceError({required this.message, required this.slice});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          if (message != null && message!.trim().isNotEmpty)
            Expanded(
              child: Text(
                message!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            )
          else
            const Spacer(),
          TextButton(
            onPressed: () => context.read<TournamentDetailBloc>().add(
              RetryDetailSlice(slice),
            ),
            child: Text(context.l10n.commonRetry),
          ),
        ],
      ),
    );
  }
}

class _CostConfigWrapper extends StatefulWidget {
  final GNEsportLeague league;
  final bool isBracketMode;

  const _CostConfigWrapper({
    super.key,
    required this.league,
    this.isBracketMode = false,
  });

  @override
  State<_CostConfigWrapper> createState() => _CostConfigWrapperState();
}

class _CostConfigWrapperState extends State<_CostConfigWrapper> {
  final _formKey = GlobalKey<CostConfigFormState>();

  void _save() {
    FocusScope.of(context).unfocus();
    final cost = _formKey.currentState?.validateAndCollect();
    if (cost == null) return;
    context.read<TournamentDetailBloc>().add(
      UpdateLeagueCostConfig(
        rankPayoutEnabled: cost.rankPayoutEnabled,
        rankPayouts: cost.rankPayouts,
        defaultMatchCost: cost.defaultMatchCost,
        defaultPerGoalEnabled: cost.defaultPerGoalEnabled,
        defaultCostPerGoal: cost.defaultCostPerGoal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final league = widget.league;
    return CollapsibleCostConfig(
      formKey: _formKey,
      isBracketMode: widget.isBracketMode,
      initialRankPayoutEnabled: league.rankPayoutEnabled,
      initialRankPayouts: league.rankPayouts,
      initialDefaultMatchCost: league.defaultMatchCost,
      initialDefaultPerGoalEnabled: league.defaultPerGoalEnabled,
      initialDefaultCostPerGoal: league.defaultCostPerGoal,
      participantCount: league.participants.length,
      action: FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.save_outlined, size: 17),
        label: Text(context.l10n.commonSave),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
