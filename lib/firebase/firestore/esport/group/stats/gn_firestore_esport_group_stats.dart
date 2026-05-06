// coverage:ignore-file
//
// Thin extension on FirebaseFirestore. The real query/snapshot plumbing
// can't be unit-tested without a Firestore fake; behaviour is covered by
// emulator-based integration tests.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/group/stats/gn_esport_group_stats_summary.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';

/// Read access to per-group lifetime aggregates. Writes go through Cloud
/// Functions — clients never write the summary doc directly. Clients can
/// only create the `_recompute_request` doc to trigger a backfill.
extension GNFirestoreEsportGroupStats on GNFirestore {
  DocumentReference<Map<String, dynamic>> _groupSummaryRef(String groupId) {
    return firestore
        .collection(GNEsportGroup.collectionName)
        .doc(groupId)
        .collection(GNEsportGroupStatsSummary.subCollectionName)
        .doc(GNEsportGroupStatsSummary.summaryDocId);
  }

  Future<GNEsportGroupStatsSummary?> getGroupSummary(String groupId) async {
    final snap = await _groupSummaryRef(groupId).get();
    if (!snap.exists) return null;
    return GNEsportGroupStatsSummary.fromFirestore(snap);
  }

  Stream<GNEsportGroupStatsSummary?> listenGroupSummary(String groupId) {
    return _groupSummaryRef(groupId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return GNEsportGroupStatsSummary.fromFirestore(snap);
    });
  }

  /// Asks the backend to backfill `esports_groups/{groupId}/stats/summary`
  /// from raw matches + standings. Implemented as a request doc so we
  /// don't need the `cloud_functions` package.
  Future<void> requestRecomputeGroupSummary(String groupId) async {
    final ref = firestore
        .collection(GNEsportGroup.collectionName)
        .doc(groupId)
        .collection(GNEsportGroupStatsSummary.subCollectionName)
        .doc(GNEsportGroupStatsSummary.recomputeRequestDocId);
    await ref.set({
      'requestedAt': FieldValue.serverTimestamp(),
      'groupId': groupId,
    });
  }
}
