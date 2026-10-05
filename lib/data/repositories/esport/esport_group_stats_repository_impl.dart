// coverage:ignore-file
//
// Thin Firestore pass-through. Methods are extensions on GNFirestore and
// can't be exercised in unit tests without a Firestore fake. Behaviour is
// covered by emulator-based tests.

import 'package:pes_arena/domain/repositories/esport/esport_group_stats_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/group/stats/gn_esport_group_stats_summary.dart';
import 'package:pes_arena/firebase/firestore/esport/group/stats/gn_firestore_esport_group_stats.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/injection_container.dart';

class EsportGroupStatsRepositoryImpl implements EsportGroupStatsRepository {
  @override
  Future<GNEsportGroupStatsSummary?> getSummary(String groupId) async {
    final firestore = getIt<GNFirestore>();
    final summary = await firestore.getGroupSummary(groupId);
    if (summary != null) return summary;
    // Lazy backfill: ask the Cloud Function to build the doc and wait for it.
    await firestore.requestRecomputeGroupSummary(groupId);
    return firestore
        .listenGroupSummary(groupId)
        .where((s) => s != null)
        .first
        .timeout(const Duration(seconds: 30));
  }
}
