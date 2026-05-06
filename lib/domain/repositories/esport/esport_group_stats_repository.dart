import 'package:pes_arena/firebase/firestore/esport/group/stats/gn_esport_group_stats_summary.dart';

abstract class EsportGroupStatsRepository {
  Future<GNEsportGroupStatsSummary?> getSummary(String groupId);

  Stream<GNEsportGroupStatsSummary?> listenSummary(String groupId);

  /// Triggers a server-side backfill. Returns immediately; caller should
  /// listen for the summary doc to update.
  Future<void> requestRecompute(String groupId);
}
