// coverage:ignore-file
//
// Thin extension on FirebaseFirestore. The real query/snapshot plumbing
// can't be unit-tested without a Firestore fake; behaviour is covered by
// emulator-based integration tests.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

import 'gn_user_h2h.dart';
import 'gn_user_stats_summary.dart';

/// Read access to per-user lifetime aggregates. Writes go through Cloud
/// Functions (`onLeagueMatchWritten`, `onRecomputeUserSummaryRequest`) —
/// clients never write the summary/h2h docs directly.
extension GNFirestoreUserStats on GNFirestore {
  /// Doc the client writes to request a backfill. The
  /// `onRecomputeUserSummaryRequest` Cloud Function consumes it.
  static const String recomputeRequestDocId = '_recompute_request';

  DocumentReference<Map<String, dynamic>> _summaryRef(String uid) {
    return firestore
        .collection(GNUser.collectionName)
        .doc(uid)
        .collection(GNUserStatsSummary.subCollectionName)
        .doc(GNUserStatsSummary.summaryDocId);
  }

  DocumentReference<Map<String, dynamic>> _h2hRef(
    String uid,
    String opponentUid,
  ) {
    return firestore
        .collection(GNUser.collectionName)
        .doc(uid)
        .collection(GNUserH2H.subCollectionName)
        .doc(opponentUid);
  }

  Future<GNUserStatsSummary?> getUserSummary(String uid) async {
    final snap = await _summaryRef(uid).get();
    if (!snap.exists) return null;
    return GNUserStatsSummary.fromFirestore(snap);
  }

  Stream<GNUserStatsSummary?> listenUserSummary(String uid) {
    return _summaryRef(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return GNUserStatsSummary.fromFirestore(snap);
    });
  }

  Future<GNUserH2H?> getUserH2H({
    required String uid,
    required String opponentUid,
  }) async {
    final snap = await _h2hRef(uid, opponentUid).get();
    if (!snap.exists) return null;
    return GNUserH2H.fromFirestore(snap);
  }

  /// Asks the backend to backfill `users/{uid}/stats/summary` (and h2h) from
  /// raw matches. Implemented as a request doc rather than a callable so we
  /// don't need to add the `cloud_functions` package; the trigger function
  /// reads the request doc and rebuilds the summary, then deletes it.
  ///
  /// Idempotent on the server side — multiple writes coalesce because the
  /// function checks `inProgress` before starting another rebuild.
  Future<void> requestRecomputeUserSummary(String uid) async {
    final ref = firestore
        .collection(GNUser.collectionName)
        .doc(uid)
        .collection(GNUserStatsSummary.subCollectionName)
        .doc(recomputeRequestDocId);
    await ref.set({
      'requestedAt': FieldValue.serverTimestamp(),
      'uid': uid,
    });
  }
}
