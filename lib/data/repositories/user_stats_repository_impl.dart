// coverage:ignore-file
//
// Thin Firestore pass-through. Methods called are extensions on
// GNFirestore (which itself wraps FirebaseFirestore.instance) and can't be
// exercised in unit tests without a Firestore fake. The behaviour is
// covered by widget/integration tests against the emulator.

import 'package:pes_arena/domain/repositories/user_stats_repository.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/stats/gn_firestore_user_stats.dart';
import 'package:pes_arena/firebase/firestore/user/stats/gn_user_h2h.dart';
import 'package:pes_arena/firebase/firestore/user/stats/gn_user_stats_summary.dart';
import 'package:pes_arena/injection_container.dart';

class UserStatsRepositoryImpl implements UserStatsRepository {
  @override
  Future<GNUserStatsSummary?> getSummary(String uid) {
    return getIt<GNFirestore>().getUserSummary(uid);
  }

  @override
  Stream<GNUserStatsSummary?> listenSummary(String uid) {
    return getIt<GNFirestore>().listenUserSummary(uid);
  }

  @override
  Future<GNUserH2H?> getH2H({
    required String uid,
    required String opponentUid,
  }) {
    return getIt<GNFirestore>().getUserH2H(uid: uid, opponentUid: opponentUid);
  }

  @override
  Future<void> requestRecompute(String uid) {
    return getIt<GNFirestore>().requestRecomputeUserSummary(uid);
  }
}
