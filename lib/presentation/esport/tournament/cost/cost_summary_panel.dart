import 'package:flutter/material.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/core/widgets/user_display.dart';
import 'package:pes_arena/widgets/gn_circle_avatar.dart';

import 'cost_calculator.dart';

class CostSummaryPanel extends StatelessWidget {
  final GNEsportLeague league;
  final List<GNEsportLeagueStat> sortedStats;
  final List<GNEsportMatch> matches;
  final bool isBracketMode;
  final List<GNEsportMatch> knockoutMatches;

  const CostSummaryPanel({
    super.key,
    required this.league,
    required this.sortedStats,
    required this.matches,
    this.isBracketMode = false,
    this.knockoutMatches = const [],
  });

  /// Hiển thị `12k` (làm tròn xuống nghìn). Tham khảo input cũng dùng đơn vị k.
  String _fmtAbs(int amount) => '${amount.abs() ~/ 1000}k';
  String _fmt(int amount) => _fmtAbs(amount);

  GNUser? _userById(String id) {
    for (final s in sortedStats) {
      if (s.userId == id) return s.user;
    }
    // For bracket mode, try to resolve from match participants
    for (final m in knockoutMatches) {
      if (m.homeTeamId == id) return m.homeTeam;
      if (m.awayTeamId == id) return m.awayTeam;
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

    final rankTransfers = <CostTransfer>[];
    if (league.rankPayoutEnabled) {
      rankTransfers.addAll(
        isBracketMode
            ? CostCalculator.bracketRankPayouts(
                knockoutMatches,
                league.rankPayouts,
              )
            : CostCalculator.rankPayouts(sortedStats, league.rankPayouts),
      );
    }
    final matchTransfers = <CostTransfer>[];
    if (hasMatchCost) {
      matchTransfers.addAll(CostCalculator.matchCosts(matches));
    }

    final mergedRank = _mergeByPair(rankTransfers);
    final mergedMatch = _mergeByPair(matchTransfers);

    final allTransfers = [...rankTransfers, ...matchTransfers];
    final net = CostCalculator.netByUser(allTransfers);
    final netEntries = net.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
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
          if (mergedRank.isEmpty && mergedMatch.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'Chưa có khoản nào',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          if (mergedRank.isNotEmpty) ...[
            _SectionHeading(
              label: isBracketMode ? 'Theo bracket' : 'Theo thứ hạng',
            ),
            ...mergedRank.map(
              (t) => _TransferRow(
                transfer: t,
                fromUser: _userById(t.fromUserId),
                toUser: _userById(t.toUserId),
                amountText: _fmt(t.amount),
              ),
            ),
          ],
          if (mergedMatch.isNotEmpty) ...[
            if (mergedRank.isNotEmpty) const SizedBox(height: 6),
            const _SectionHeading(label: 'Theo trận'),
            ...mergedMatch.map(
              (t) => _TransferRow(
                transfer: t,
                fromUser: _userById(t.fromUserId),
                toUser: _userById(t.toUserId),
                amountText: _fmt(t.amount),
              ),
            ),
          ],
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
                        displayNameOrFallback(user),
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${isReceiver ? '+' : '-'}${_fmtAbs(e.value.abs())}',
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

  static List<CostTransfer> _mergeByPair(List<CostTransfer> transfers) {
    final byPair = <String, int>{};
    final pairOrder = <String, (String, String)>{};
    for (final t in transfers) {
      final key = '${t.fromUserId}|${t.toUserId}';
      pairOrder.putIfAbsent(key, () => (t.fromUserId, t.toUserId));
      byPair[key] = (byPair[key] ?? 0) + t.amount;
    }
    return byPair.entries.where((e) => e.value > 0).map((e) {
      final (from, to) = pairOrder[e.key]!;
      return CostTransfer(fromUserId: from, toUserId: to, amount: e.value);
    }).toList()..sort((a, b) => b.amount.compareTo(a.amount));
  }
}

class _SectionHeading extends StatelessWidget {
  final String label;

  const _SectionHeading({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  final CostTransfer transfer;
  final GNUser? fromUser;
  final GNUser? toUser;
  final String amountText;

  const _TransferRow({
    required this.transfer,
    required this.fromUser,
    required this.toUser,
    required this.amountText,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GNCircleAvatar(size: 22, photoUrl: fromUser?.photoUrl),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              displayNameOrFallback(fromUser),
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
              displayNameOrFallback(toUser),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          const Spacer(),
          Text(
            amountText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
