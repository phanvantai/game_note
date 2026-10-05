import 'package:pes_arena/firebase/firestore/esport/group/stats/gn_esport_group_stats_summary.dart';

abstract class EsportGroupStatsRepository {
  /// Lifetime summary for [groupId]. The API implementation always returns a
  /// freshly computed summary; `null` only comes from the legacy Firestore
  /// implementation when no summary doc exists yet.
  Future<GNEsportGroupStatsSummary?> getSummary(String groupId);
}
