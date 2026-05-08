import 'dart:math' as math;

import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';

/// Một chuyển khoản chi phí từ A → B (A trả cho B `amount` VND).
class CostTransfer {
  final String fromUserId;
  final String toUserId;
  final int amount;

  const CostTransfer({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });
}

/// Tính toán chi phí "tiền máy / ăn uống" giữa người chơi.
/// Pure logic — không state, không I/O. Hoà → không tính.
class CostCalculator {
  /// Tính tiền theo thứ hạng. `sortedStats` đã được sort theo
  /// points DESC → goalDifference DESC → goals DESC (logic đã có sẵn ở bloc).
  ///
  /// `rankPayouts[i]` là số tiền hạng `i + 2` phải trả cho hạng nhất.
  /// Vd 4 người với rankPayouts = [50000, 100000, 150000]:
  ///   hạng 2 trả 50k, hạng 3 trả 100k, hạng 4 trả 150k → hạng 1 nhận 300k.
  ///
  /// Trả về list các transfer (from = người trả, to = hạng nhất).
  static List<CostTransfer> rankPayouts(
    List<GNEsportLeagueStat> sortedStats,
    List<int> rankPayouts,
  ) {
    if (sortedStats.length < 2 || rankPayouts.isEmpty) return const [];
    final winnerId = sortedStats.first.userId;
    final transfers = <CostTransfer>[];
    // i=0 là hạng nhất (người nhận); hạng (i+1) trả `rankPayouts[i-1]`.
    for (int i = 1; i < sortedStats.length; i++) {
      final amount = i - 1 < rankPayouts.length ? rankPayouts[i - 1] : 0;
      if (amount <= 0) continue;
      transfers.add(CostTransfer(
        fromUserId: sortedStats[i].userId,
        toUserId: winnerId,
        amount: amount,
      ));
    }
    return transfers;
  }

  /// Tính tiền per-match. Với mỗi trận `isFinished == true`:
  ///   - cost = match.matchCost (null hoặc <= 0 ⇒ skip — user chưa bật cho trận này)
  ///   - hoà ⇒ skip
  ///   - thua trả thắng cost
  /// Sau đó netting theo từng cặp (A↔B) để hiển thị gọn.
  static List<CostTransfer> matchCosts(List<GNEsportMatch> matches) {
    // pairKey → net amount (positive: low.id trả high.id, negative: ngược lại)
    final pairNet = <String, int>{};
    final pairLowHigh = <String, (String, String)>{};

    for (final m in matches) {
      if (!m.isFinished) continue;
      final home = m.homeScore;
      final away = m.awayScore;
      if (home == null || away == null || home == away) continue;
      final cost = m.matchCost ?? 0;
      if (cost <= 0) continue;

      final winner = home > away ? m.homeTeamId : m.awayTeamId;
      final loser = home > away ? m.awayTeamId : m.homeTeamId;

      final low = winner.compareTo(loser) < 0 ? winner : loser;
      final high = winner.compareTo(loser) < 0 ? loser : winner;
      final key = '$low|$high';
      pairLowHigh[key] = (low, high);
      // sign: nếu low là loser, low trả high → +cost
      //       nếu low là winner, high trả low → -cost
      final sign = low == loser ? 1 : -1;
      pairNet[key] = (pairNet[key] ?? 0) + sign * cost;
    }

    final transfers = <CostTransfer>[];
    pairNet.forEach((key, net) {
      if (net == 0) return;
      final (low, high) = pairLowHigh[key]!;
      if (net > 0) {
        transfers.add(CostTransfer(
          fromUserId: low,
          toUserId: high,
          amount: net,
        ));
      } else {
        transfers.add(CostTransfer(
          fromUserId: high,
          toUserId: low,
          amount: -net,
        ));
      }
    });
    return transfers;
  }

  /// Tính tiền theo bracket ranking cho Cup / Full mode.
  ///
  /// `rankPayouts[i]` = số tiền mỗi người bị loại ở nhóm thứ `i+1` phải trả
  /// cho champion:
  ///   i=0 → runner-up (1 người, thua trận final)
  ///   i=1 → mỗi người thua bán kết
  ///   i=2 → mỗi người thua tứ kết
  ///   …
  ///
  /// Chỉ tính cho những trận đã `isFinished`. Champion được xác định từ
  /// winner của trận ở `knockoutRound` cao nhất.
  static List<CostTransfer> bracketRankPayouts(
    List<GNEsportMatch> knockoutMatches,
    List<int> rankPayouts,
  ) {
    if (knockoutMatches.isEmpty || rankPayouts.isEmpty) return const [];

    int maxRound = 0;
    for (final m in knockoutMatches) {
      maxRound = math.max(maxRound, m.knockoutRound ?? 0);
    }

    final finalMatch = knockoutMatches
        .where((m) => m.knockoutRound == maxRound && m.isFinished)
        .firstOrNull;
    if (finalMatch == null) return const [];

    final homeScore = finalMatch.homeScore ?? 0;
    final awayScore = finalMatch.awayScore ?? 0;
    if (homeScore == awayScore) return const [];

    final championId =
        homeScore > awayScore ? finalMatch.homeTeamId : finalMatch.awayTeamId;

    final transfers = <CostTransfer>[];
    for (int i = 0; i < rankPayouts.length; i++) {
      final amount = rankPayouts[i];
      if (amount <= 0) continue;

      final round = maxRound - i;
      if (round < 0) break;

      final roundMatches = knockoutMatches
          .where((m) => (m.knockoutRound ?? 0) == round && m.isFinished);

      for (final m in roundMatches) {
        final home = m.homeScore ?? 0;
        final away = m.awayScore ?? 0;
        if (home == away) continue;
        final loserId = home > away ? m.awayTeamId : m.homeTeamId;
        if (loserId.isEmpty || loserId == championId) continue;
        transfers.add(
          CostTransfer(fromUserId: loserId, toUserId: championId, amount: amount),
        );
      }
    }
    return transfers;
  }

  /// Tổng kết "ròng" mỗi user từ list transfer:
  /// dương = tổng nhận về sau khi trừ phải trả, âm = phải trả ròng.
  static Map<String, int> netByUser(List<CostTransfer> transfers) {
    final net = <String, int>{};
    for (final t in transfers) {
      net[t.fromUserId] = (net[t.fromUserId] ?? 0) - t.amount;
      net[t.toUserId] = (net[t.toUserId] ?? 0) + t.amount;
    }
    return net;
  }
}
