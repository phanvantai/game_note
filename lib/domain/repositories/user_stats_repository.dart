import 'package:pes_arena/firebase/firestore/user/stats/gn_user_h2h.dart';
import 'package:pes_arena/firebase/firestore/user/stats/gn_user_stats_summary.dart';

abstract class UserStatsRepository {
  Future<GNUserStatsSummary?> getSummary(String uid);

  Stream<GNUserStatsSummary?> listenSummary(String uid);

  Future<GNUserH2H?> getH2H({
    required String uid,
    required String opponentUid,
  });

  /// Triggers a server-side backfill. Returns immediately; caller should
  /// poll/listen for the summary doc to appear.
  Future<void> requestRecompute(String uid);
}
