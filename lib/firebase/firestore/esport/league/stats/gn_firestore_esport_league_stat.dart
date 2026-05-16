import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';

import '../gn_esport_league.dart';
import 'gn_esport_league_stat.dart';

/// Composite key for a stat row: (userId, groupId). groupId is null for
/// league-wide stats (league/cup mode) and 'A'/'B'/... for full-mode group
/// stats.
typedef _StatKey = ({String userId, String? groupId});

extension GNFirestoreEsportLeagueStat on GNFirestore {
  // create a stat for a user in a league.
  // [groupId] is set for full-mode group-scoped stats; null for league-wide.
  Future<void> addLeagueStat({
    required String userId,
    required String leagueId,
    String? groupId,
  }) async {
    final leagueStatCollection = firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportLeagueStat.collectionName);

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
      groupId: groupId,
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

  /// Admin-only escape hatch: nuke every stat doc in the league and
  /// recreate them from scratch by folding finished matches.
  ///
  /// Why delete-and-recreate instead of in-place update: legacy bugs (and
  /// some manual data edits) have left leagues with duplicate stat rows
  /// per user, orphan rows for removed participants, and rows with missing
  /// fields. Any in-place reconcile is sensitive to which docs already
  /// exist. Tearing down and rebuilding gives one deterministic shape:
  ///
  /// - league / cup mode: exactly one row per user (groupId = null).
  ///   Users are the union of `league.participants` and any home/away
  ///   team referenced by a match (rescues orphans).
  /// - full mode: one row per (user, group) pair. Group membership is
  ///   derived from group-phase matches' (groupId, homeTeamId, awayTeamId);
  ///   if no group match references a user yet, their pre-existing
  ///   stat doc's groupId is preserved as a fallback.
  ///
  /// Knockout matches contribute nothing — bracket rounds don't track stats.
  ///
  /// Not transactional (queries can't run inside Firestore transactions and
  /// this is a manual admin action without concurrent contention to worry
  /// about). If a user updates a match mid-reconcile, just re-run reconcile.
  Future<void> recomputeLeagueStats(String leagueId) async {
    final leagueRef = firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId);
    final statsCollection =
        leagueRef.collection(GNEsportLeagueStat.collectionName);
    final matchesCollection =
        leagueRef.collection(GNEsportMatch.collectionName);

    final results = await Future.wait([
      leagueRef.get(),
      statsCollection.get(),
      matchesCollection.get(),
    ]);
    final leagueSnap = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final statSnaps =
        (results[1] as QuerySnapshot<Map<String, dynamic>>).docs;
    final allMatches =
        (results[2] as QuerySnapshot<Map<String, dynamic>>)
            .docs
            .map(GNEsportMatch.fromFirestore)
            .toList();

    final mode = leagueSnap.exists
        ? GNEsportLeague.fromFirestore(leagueSnap).mode
        : TournamentMode.league;
    final participants = leagueSnap.exists
        ? GNEsportLeague.fromFirestore(leagueSnap).participants
        : const <String>[];

    // --- Step 1: determine which (user, group) rows should exist ---
    final desiredRows = <_StatKey>{};
    if (mode == TournamentMode.full) {
      // Derive group membership from group-phase matches.
      final groupOfUser = <String, String>{};
      for (final m in allMatches) {
        if (m.phase != 'group' || m.groupId == null) continue;
        if (m.homeTeamId.isNotEmpty) groupOfUser[m.homeTeamId] = m.groupId!;
        if (m.awayTeamId.isNotEmpty) groupOfUser[m.awayTeamId] = m.groupId!;
      }
      // Fallback to pre-existing stat docs' groupId for users not yet in any
      // group match — preserves group assignment for newly-added players.
      for (final s in statSnaps) {
        final stat = GNEsportLeagueStat.fromFirestore(s);
        if (stat.groupId != null && !groupOfUser.containsKey(stat.userId)) {
          groupOfUser[stat.userId] = stat.groupId!;
        }
      }
      for (final entry in groupOfUser.entries) {
        desiredRows.add((userId: entry.key, groupId: entry.value));
      }
    } else {
      // league / cup: one row per user. Pull from participants + match
      // teams (covers orphans whose user was removed from participants).
      final users = <String>{
        ...participants,
        for (final m in allMatches) ...[m.homeTeamId, m.awayTeamId],
      }..removeWhere((id) => id.isEmpty);
      for (final u in users) {
        desiredRows.add((userId: u, groupId: null));
      }
    }

    // --- Step 2: fold finished matches into per-row totals ---
    final totals = <_StatKey, _ReconcileTotals>{
      for (final row in desiredRows) row: _ReconcileTotals(),
    };
    for (final m in allMatches) {
      if (m.isFinished != true) continue;
      if (m.phase == 'knockout') continue;
      final h = m.homeScore;
      final a = m.awayScore;
      if (h == null || a == null) continue;
      final groupId = m.groupId;
      totals[(userId: m.homeTeamId, groupId: groupId)]
          ?.apply(scoredFor: h, scoredAgainst: a);
      totals[(userId: m.awayTeamId, groupId: groupId)]
          ?.apply(scoredFor: a, scoredAgainst: h);
    }

    // --- Step 3: delete all existing rows + write fresh rows, in chunks ---
    final ops = <_StatOp>[
      for (final s in statSnaps) _StatOp.delete(s.reference),
      for (final row in desiredRows)
        _StatOp.write(
          statsCollection.doc(),
          GNEsportLeagueStat(
            id: '', // ignored by toMap
            userId: row.userId,
            leagueId: leagueId,
            matchesPlayed: totals[row]!.mp,
            goals: totals[row]!.gf,
            goalsConceded: totals[row]!.ga,
            wins: totals[row]!.w,
            draws: totals[row]!.d,
            losses: totals[row]!.l,
            groupId: row.groupId,
          ).toMap(),
        ),
    ];

    // Stay under Firestore's 500-write-per-batch ceiling.
    const batchLimit = 499;
    for (int i = 0; i < ops.length; i += batchLimit) {
      final end = (i + batchLimit).clamp(0, ops.length);
      final batch = firestore.batch();
      for (final op in ops.sublist(i, end)) {
        if (op.data == null) {
          batch.delete(op.ref);
        } else {
          batch.set(op.ref, op.data!);
        }
      }
      await batch.commit();
    }
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

/// One delete-or-write op in the recompute teardown/rebuild plan. `data`
/// null means delete; non-null means set.
class _StatOp {
  final DocumentReference<Map<String, dynamic>> ref;
  final Map<String, dynamic>? data;
  const _StatOp.delete(this.ref) : data = null;
  const _StatOp.write(this.ref, Map<String, dynamic> this.data);
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
