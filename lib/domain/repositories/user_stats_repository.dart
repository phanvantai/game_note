import 'package:pes_arena/firebase/firestore/user/stats/gn_user_h2h.dart';
import 'package:pes_arena/firebase/firestore/user/stats/gn_user_stats_summary.dart';

abstract class UserStatsRepository {
  /// Lifetime summary for [uid]. The API implementation always returns a
  /// freshly computed summary; `null` only comes from the legacy Firestore
  /// implementation when no summary doc exists yet.
  Future<GNUserStatsSummary?> getSummary(String uid);

  Future<GNUserH2H?> getH2H({required String uid, required String opponentUid});
}
