import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';

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
                _CostConfigSection(
                  key: ValueKey(
                    '${league.id}-${league.rankPayoutEnabled}-${league.rankPayouts.join(',')}-${league.defaultMatchCost}',
                  ),
                  league: league,
                ),
                const SizedBox(height: 12),
              ],
              CostSummaryPanel(
                league: league,
                sortedStats: state.participants,
                matches: state.matches,
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

class _CostConfigSection extends StatefulWidget {
  final GNEsportLeague league;

  const _CostConfigSection({super.key, required this.league});

  @override
  State<_CostConfigSection> createState() => _CostConfigSectionState();
}

class _CostConfigSectionState extends State<_CostConfigSection> {
  final GlobalKey<CostConfigFormState> _formKey =
      GlobalKey<CostConfigFormState>();
  bool _expanded = false;

  void _save() {
    FocusScope.of(context).unfocus();
    final cost = _formKey.currentState?.validateAndCollect();
    if (cost == null) return;
    context.read<TournamentDetailBloc>().add(
      UpdateLeagueCostConfig(
        rankPayoutEnabled: cost.rankPayoutEnabled,
        rankPayouts: cost.rankPayouts,
        defaultMatchCost: cost.defaultMatchCost,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final league = widget.league;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(
                      Icons.tune_outlined,
                      size: 19,
                      color: colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cấu hình chi phí',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 22,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    height: 1,
                    color: colorScheme.outline.withValues(alpha: 0.18),
                  ),
                  const SizedBox(height: 12),
                  CostConfigForm(
                    key: _formKey,
                    initialRankPayoutEnabled: league.rankPayoutEnabled,
                    initialRankPayouts: league.rankPayouts,
                    initialDefaultMatchCost: league.defaultMatchCost,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save_outlined, size: 17),
                      label: const Text('Lưu'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState:
                _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
