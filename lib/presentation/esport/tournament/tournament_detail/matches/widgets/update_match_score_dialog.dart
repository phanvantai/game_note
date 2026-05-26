import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_team.dart';

void showUpdateMatchScoreDialog(BuildContext context, GNEsportMatch match) {
  final homeCtrl = TextEditingController(
    text: match.isFinished ? (match.homeScore?.toString() ?? '') : '',
  );
  final awayCtrl = TextEditingController(
    text: match.isFinished ? (match.awayScore?.toString() ?? '') : '',
  );
  final colorScheme = Theme.of(context).colorScheme;
  final league = context.read<TournamentDetailBloc>().state.league;
  final defaultPrefillK = (league?.defaultMatchCost ?? 50000) ~/ 1000;
  final defaultPerGoalK = (league?.defaultCostPerGoal ?? 50000) ~/ 1000;
  bool costEnabled = (match.matchCost ?? 0) > 0;
  bool perGoalEnabled = (match.costPerGoal ?? 0) > 0
      ? true
      : (league?.defaultPerGoalEnabled ?? false);
  final matchCostCtrl = TextEditingController(
    text:
        ((match.matchCost ?? 0) > 0
                ? (match.matchCost! ~/ 1000)
                : defaultPrefillK)
            .toString(),
  );
  final perGoalCostCtrl = TextEditingController(
    text:
        ((match.costPerGoal ?? 0) > 0
                ? (match.costPerGoal! ~/ 1000)
                : defaultPerGoalK)
            .toString(),
  );

  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocalState) => AlertDialog(
        title: Text(context.l10n.tournamentUpdateResultTitle),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
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
                          controller: homeCtrl,
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
                          controller: awayCtrl,
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
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(context.l10n.tournamentMatchHasCost),
                  value: costEnabled,
                  onChanged: (v) => setLocalState(() => costEnabled = v),
                ),
                if (costEnabled) ...[
                  TextField(
                    controller: matchCostCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: context.l10n.tournamentMatchCostLabel,
                      prefixIcon: const Icon(Icons.attach_money, size: 20),
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(context.l10n.tournamentAddGoalDifferenceCost),
                    value: perGoalEnabled,
                    onChanged: (v) => setLocalState(() => perGoalEnabled = v),
                  ),
                  if (perGoalEnabled)
                    TextField(
                      controller: perGoalCostCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: context.l10n.costPerGoalHint,
                        helperText:
                            context.l10n.tournamentGoalDifferenceCostHelp,
                        prefixIcon: const Icon(Icons.sports_soccer, size: 20),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(context.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              FocusScope.of(ctx).unfocus();
              if (homeCtrl.text.isEmpty || awayCtrl.text.isEmpty) {
                showToast(
                  context.l10n.tournamentScoreRequired,
                  gravity: ToastGravity.TOP,
                );
                return;
              }
              final homeScore = int.tryParse(homeCtrl.text);
              final awayScore = int.tryParse(awayCtrl.text);
              if (homeScore == null || awayScore == null) return;
              final matchCost = costEnabled
                  ? (int.tryParse(matchCostCtrl.text.trim()) ??
                            defaultPrefillK) *
                        1000
                  : 0;
              final costPerGoal = (costEnabled && perGoalEnabled)
                  ? (int.tryParse(perGoalCostCtrl.text.trim()) ??
                            defaultPerGoalK) *
                        1000
                  : 0;
              context.read<TournamentDetailBloc>().add(
                UpdateEsportMatch(
                  match.copyWith(
                    homeScore: homeScore,
                    awayScore: awayScore,
                    matchCost: matchCost,
                    costPerGoal: costPerGoal,
                  ),
                ),
              );
              Navigator.of(ctx).pop();
            },
            child: Text(context.l10n.commonUpdate),
          ),
        ],
      ),
    ),
  );
}
