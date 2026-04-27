import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/widgets/gn_circle_avatar.dart';

import 'cost_calculator.dart';

class CostSummaryPanel extends StatelessWidget {
  final GNEsportLeague league;
  final List<GNEsportLeagueStat> sortedStats;
  final List<GNEsportMatch> matches;

  const CostSummaryPanel({
    super.key,
    required this.league,
    required this.sortedStats,
    required this.matches,
  });

  static final NumberFormat _vnd = NumberFormat.decimalPattern('vi_VN');

  String _fmt(int amount) => '${_fmtAbs(amount.abs())}đ';
  String _fmtAbs(int amount) => _vnd.format(amount);

  static const String _fallbackName = 'Người chơi';

  GNUser? _userById(String id) {
    for (final s in sortedStats) {
      if (s.userId == id) return s.user;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final hasMatchCost = matches.any((m) => (m.matchCost ?? 0) > 0);
    if (!league.rankPayoutEnabled && !hasMatchCost) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final isFinished = league.status == GNEsportLeagueStatus.finished.value;

    final transfers = <CostTransfer>[];
    if (league.rankPayoutEnabled) {
      transfers.addAll(
        CostCalculator.rankPayouts(sortedStats, league.rankPayouts),
      );
    }
    if (hasMatchCost) {
      transfers.addAll(CostCalculator.matchCosts(matches));
    }

    final byPair = <String, int>{};
    final pairOrder = <String, (String, String)>{};
    for (final t in transfers) {
      final key = '${t.fromUserId}|${t.toUserId}';
      pairOrder.putIfAbsent(key, () => (t.fromUserId, t.toUserId));
      byPair[key] = (byPair[key] ?? 0) + t.amount;
    }

    final mergedTransfers = byPair.entries
        .where((e) => e.value > 0)
        .map((e) {
          final (from, to) = pairOrder[e.key]!;
          return CostTransfer(
            fromUserId: from,
            toUserId: to,
            amount: e.value,
          );
        })
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    final net = CostCalculator.netByUser(transfers);
    final netEntries = net.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.payments_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Chi phí',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 6),
              if (!isFinished)
                Text(
                  '(tạm tính)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (mergedTransfers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Chưa có khoản nào',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            )
          else
            ...mergedTransfers.map((t) {
              final fromUser = _userById(t.fromUserId);
              final toUser = _userById(t.toUserId);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    GNCircleAvatar(size: 22, photoUrl: fromUser?.photoUrl),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        fromUser?.displayName ??
                            _fallbackName,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 6),
                    GNCircleAvatar(size: 22, photoUrl: toUser?.photoUrl),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        toUser?.displayName ?? _fallbackName,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _fmt(t.amount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (netEntries.isNotEmpty) ...[
            const SizedBox(height: 8),
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 8),
            Text(
              'Tổng ròng',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            ...netEntries.where((e) => e.value != 0).map((e) {
              final user = _userById(e.key);
              final isReceiver = e.value > 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    GNCircleAvatar(size: 20, photoUrl: user?.photoUrl),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        user?.displayName ?? _fallbackName,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${isReceiver ? '+' : '-'}${_fmtAbs(e.value.abs())}đ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isReceiver
                            ? Colors.green[700]
                            : theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
