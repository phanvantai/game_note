import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import '../../cost/collapsible_cost_config.dart';
import '../../cost/cost_config_form.dart';
import '../../cost/cost_summary_panel.dart';
import '../bloc/tournament_detail_bloc.dart';

class CostSplitView extends StatelessWidget {
  const CostSplitView({super.key});

  Future<void> _refresh(BuildContext context) async {
    final bloc = context.read<TournamentDetailBloc>();
    final leagueId = bloc.state.league?.id;
    if (leagueId == null) return;
    final tickBefore = bloc.state.refreshTick;
    bloc.add(GetParticipantsAndMatches(leagueId));
    await bloc.stream.firstWhere((s) => s.refreshTick > tickBefore);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentDetailBloc, TournamentDetailState>(
      builder: (context, state) {
        final league = state.league;
        final isBracketMode = league?.mode == TournamentMode.cup ||
            league?.mode == TournamentMode.full;
        final knockoutMatches = state.knockoutMatches;
        if (league == null) {
          return RefreshIndicator(
            onRefresh: () => _refresh(context),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(
                  height: 400,
                  child: AppEmptyState(
                    icon: Icons.payments_outlined,
                    title: 'Đang tải chi phí',
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _refresh(context),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              if (state.currentUserIsLeagueAdmin) ...[
                _CostConfigWrapper(
                  key: ValueKey(
                    '${league.id}-${league.rankPayoutEnabled}-${league.rankPayouts.join(',')}-${league.defaultMatchCost}-${league.defaultPerGoalEnabled}-${league.defaultCostPerGoal}',
                  ),
                  league: league,
                  isBracketMode: isBracketMode,
                ),
                const SizedBox(height: 12),
              ],
              CostSummaryPanel(
                league: league,
                sortedStats: state.participants,
                matches: state.matches,
                isBracketMode: isBracketMode,
                knockoutMatches: knockoutMatches,
              ),
              if (!league.rankPayoutEnabled &&
                  !state.matches.any((m) => (m.matchCost ?? 0) > 0))
                const SizedBox(
                  height: 320,
                  child: AppEmptyState(
                    icon: Icons.payments_outlined,
                    title: 'Chưa có chi phí',
                    subtitle:
                        'Bật cấu hình chi phí hoặc nhập tiền trong từng trận',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CostConfigWrapper extends StatefulWidget {
  final GNEsportLeague league;
  final bool isBracketMode;

  const _CostConfigWrapper({super.key, required this.league, this.isBracketMode = false});

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
        label: const Text('Lưu'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
