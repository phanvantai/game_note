import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/gn_firestore_user.dart';

import '../gn_esport_league.dart';
import 'gn_esport_league_stat.dart';

extension GNFirestoreEsportLeagueStat on GNFirestore {
  // create a stat for a user in a league
  Future<void> addLeagueStat({
    required String userId,
    required String leagueId,
  }) async {
    final leagueStatCollection = firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportLeagueStat.collectionName);

    // Create a new league stat with default values
    final newLeagueStat = GNEsportLeagueStat(
      id: leagueStatCollection.doc().id,
      userId: userId,
      leagueId: leagueId,
      matchesPlayed: 0,
      goals: 0,
      goalsConceded: 0,
      wins: 0,
      draws: 0,
      losses: 0,
    );

    await leagueStatCollection.doc(newLeagueStat.id).set(newLeagueStat.toMap());
  }

  // get all stats for a league
  Future<List<GNEsportLeagueStat>> getLeagueStats(String leagueId) async {
    final snapshot = await firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportLeagueStat.collectionName)
        .get();

    List<GNEsportLeagueStat> leagues = [];

    // Extract all user IDs first
    final userIds = snapshot.docs
        .map((doc) => GNEsportLeagueStat.fromFirestore(doc).userId)
        .toList();

    // Batch load all users at once to avoid N+1 query problem
    final usersMap = await getUsersById(userIds);

    // Build the final list with user data
    for (final doc in snapshot.docs) {
      final stats = GNEsportLeagueStat.fromFirestore(doc);
      final user = usersMap[stats.userId];
      leagues.add(stats.copyWith(user: user));
    }
    return leagues;
  }

  /// Recompute all stat docs for a league from its finished matches and
  /// overwrite the stored values. Admin-only escape hatch for cases where
  /// stats drifted from reality (e.g. legacy non-transactional update bugs,
  /// manually deleted matches in console). Idempotent — safe to re-run.
  ///
  /// Uses a single batched write rather than a transaction: queries (which
  /// we need for the stats + matches collections) aren't allowed inside
  /// Firestore transactions, and reconcile is a manual admin action with
  /// no concurrent contention to worry about. If an admin races a normal
  /// match update against a reconcile, just re-run reconcile after.
  Future<void> recomputeLeagueStats(String leagueId) async {
    final statsCollection = firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportLeagueStat.collectionName);
    final matchesCollection = firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportMatch.collectionName);

    final results = await Future.wait([
      statsCollection.get(),
      matchesCollection
          .where(GNEsportMatch.fieldIsFinished, isEqualTo: true)
          .get(),
    ]);
    final statSnaps = results[0].docs;
    final matchSnaps = results[1].docs;

    // Initialise totals at zero for every existing stat doc — players with
    // no finished matches still need their docs reset (in case they were
    // stale).
    final totals = <String, _ReconcileTotals>{
      for (final s in statSnaps)
        GNEsportLeagueStat.fromFirestore(s).userId: _ReconcileTotals(),
    };

    for (final m in matchSnaps) {
      final match = GNEsportMatch.fromFirestore(m);
      final h = match.homeScore;
      final a = match.awayScore;
      if (h == null || a == null) continue;
      // Silently ignore matches whose players don't have a stat doc — the
      // audit log will already have flagged them as orphans.
      totals[match.homeTeamId]?.apply(scoredFor: h, scoredAgainst: a);
      totals[match.awayTeamId]?.apply(scoredFor: a, scoredAgainst: h);
    }

    final batch = firestore.batch();
    for (final s in statSnaps) {
      final userId = GNEsportLeagueStat.fromFirestore(s).userId;
      final t = totals[userId]!;
      batch.update(s.reference, {
        GNEsportLeagueStat.fieldMatchesPlayed: t.mp,
        GNEsportLeagueStat.fieldGoals: t.gf,
        GNEsportLeagueStat.fieldGoalsConceded: t.ga,
        GNEsportLeagueStat.fieldWins: t.w,
        GNEsportLeagueStat.fieldDraws: t.d,
        GNEsportLeagueStat.fieldLosses: t.l,
      });
    }
    await batch.commit();
  }

  // listen to updates of a league stat
  Stream<List<GNEsportLeagueStat>> listenForLeagueStats(String leagueId) {
    return firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportLeagueStat.collectionName)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GNEsportLeagueStat.fromFirestore(doc))
          .toList();
    });
  }
}

/// Mutable accumulator used by `recomputeLeagueStats` to fold finished
/// matches into per-player totals.
class _ReconcileTotals {
  int mp = 0;
  int gf = 0;
  int ga = 0;
  int w = 0;
  int d = 0;
  int l = 0;

  void apply({required int scoredFor, required int scoredAgainst}) {
    mp++;
    gf += scoredFor;
    ga += scoredAgainst;
    if (scoredFor > scoredAgainst) {
      w++;
    } else if (scoredFor == scoredAgainst) {
      d++;
    } else {
      l++;
    }
  }
}
