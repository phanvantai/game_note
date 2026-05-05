import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';

import 'gn_esport_match.dart';

/// Thrown when a match update detects another writer has modified the match
/// since the local copy was loaded. UI should toast and refresh — the
/// listener stream will already have surfaced the new values.
class ConcurrentMatchUpdateException implements Exception {
  final String matchId;
  ConcurrentMatchUpdateException(this.matchId);

  @override
  String toString() =>
      'ConcurrentMatchUpdateException: match $matchId was updated by '
      'someone else while you were editing it.';
}

extension GnFirestoreEsportLeagueMatch on GNFirestore {
  Stream<List<GNEsportMatch>> listenForMatchesUpdated(String leagueId) {
    return firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportMatch.collectionName)
        .snapshots() // This will return a stream of snapshots in real-time
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => GNEsportMatch.fromFirestore(doc))
          .toList();
    });
  }

  Future<void> generateRound({
    required String leagueId,
    required List<String> teamIds,
  }) async {
    final batch = firestore.batch(); // To write multiple documents at once.

    List<GNEsportMatch> matches = [];

    // Generate matches for each team against every other team.
    for (int i = 0; i < teamIds.length; i++) {
      for (int j = i + 1; j < teamIds.length; j++) {
        // Create a match with team i as home and team j as away
        String matchId = firestore
            .collection(
                '${GNEsportLeague.collectionName}/$leagueId/${GNEsportMatch.collectionName}')
            .doc()
            .id;

        final match = GNEsportMatch(
          id: matchId,
          homeTeamId: teamIds[i],
          awayTeamId: teamIds[j],
          homeScore: 0, // Default score, can be updated later
          awayScore: 0, // Default score, can be updated later
          date: DateTime.now(), // You can specify the match date if needed
          isFinished: false, // Match is not finished when created
          leagueId: leagueId,
        );

        // Add match to Firestore batch
        batch.set(
          firestore.doc(
              '${GNEsportLeague.collectionName}/$leagueId/${GNEsportMatch.collectionName}/$matchId'),
          match.toMap(),
        );

        // Add match to the local list for future reference
        matches.add(match);
      }
    }

    // Commit the batch write to Firestore
    await batch.commit();
  }

  // get matches of a league
  Future<List<GNEsportMatch>> getMatches(String leagueId) async {
    final snapshot = await firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportMatch.collectionName)
        .get();

    List<GNEsportMatch> matches = [];

    // Extract all unique user IDs from matches
    final userIds = <String>{};
    final matchDocs =
        snapshot.docs.map((doc) => GNEsportMatch.fromFirestore(doc)).toList();

    for (final match in matchDocs) {
      userIds.add(match.homeTeamId);
      userIds.add(match.awayTeamId);
    }

    // Batch load all users at once to avoid N+1 query problem
    final usersMap = await getUsersById(userIds.toList());

    // Build the final list with user data
    for (final match in matchDocs) {
      final homeTeam = usersMap[match.homeTeamId];
      final awayTeam = usersMap[match.awayTeamId];
      matches.add(match.copyWith(
        homeTeam: homeTeam,
        awayTeam: awayTeam,
      ));
    }
    return matches;
  }

  /// Update a match score atomically.
  ///
  /// Wraps everything (read match + read both stat docs + write all 3) in a
  /// Firestore transaction. If any of those docs is modified by another
  /// writer mid-transaction, Firestore retries automatically. This fixes
  /// the lost-update / double-decrement bugs that the old read-modify-write
  /// flow had when two admins updated matches concurrently.
  ///
  /// [expectedUpdatedAt] — if provided, the transaction throws
  /// [ConcurrentMatchUpdateException] when the match's `updatedAt` differs
  /// from the value the UI captured when the dialog opened (i.e. someone
  /// else committed an update in the meantime). Pass null to skip the
  /// check (e.g. for non-interactive flows).
  Future<void> updateMatch({
    required String matchId,
    required String leagueId,
    int? homeScore,
    int? awayScore,
    int? matchCost,
    Timestamp? expectedUpdatedAt,
  }) async {
    final matchRef = firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportMatch.collectionName)
        .doc(matchId);

    // Resolve stat document refs OUTSIDE the transaction. The stats
    // collection is keyed by an opaque doc id — we have to query by userId
    // first. Doing this inside the transaction would require all reads
    // before any writes anyway, but the query API isn't available on
    // Transaction. If a stat doc is recreated between this lookup and the
    // commit, the next listener tick will reconcile.
    final initialMatch = await matchRef.get();
    if (!initialMatch.exists) {
      throw Exception('Match not found');
    }
    final m = GNEsportMatch.fromFirestore(initialMatch);
    final statRefs = await Future.wait([
      _statRefForUser(leagueId, m.homeTeamId),
      _statRefForUser(leagueId, m.awayTeamId),
    ]);
    final homeStatRef = statRefs[0];
    final awayStatRef = statRefs[1];

    await firestore.runTransaction((txn) async {
      // Reads first — required by Firestore transaction semantics.
      final matchSnap = await txn.get(matchRef);
      if (!matchSnap.exists) {
        throw Exception('Match not found');
      }
      final current = GNEsportMatch.fromFirestore(matchSnap);

      if (expectedUpdatedAt != null &&
          current.updatedAt != null &&
          current.updatedAt != expectedUpdatedAt) {
        throw ConcurrentMatchUpdateException(matchId);
      }

      final homeStatSnap = await txn.get(homeStatRef);
      final awayStatSnap = await txn.get(awayStatRef);
      final homeStats = GNEsportLeagueStat.fromFirestore(homeStatSnap);
      final awayStats = GNEsportLeagueStat.fromFirestore(awayStatSnap);

      final newMatch = current.copyWith(
        homeScore: homeScore,
        awayScore: awayScore,
        isFinished: homeScore != null && awayScore != null,
        matchCost: matchCost ?? current.matchCost,
      );

      // Compute net delta in one pass: reverse old contribution if the
      // match was finished, then apply new contribution if it still is.
      var homeDelta = _zeroDelta;
      var awayDelta = _zeroDelta;
      if (current.isFinished) {
        final undo = _statContribution(
          current.homeScore!,
          current.awayScore!,
          sign: -1,
        );
        homeDelta = homeDelta + undo.home;
        awayDelta = awayDelta + undo.away;
      }
      if (newMatch.isFinished) {
        final apply = _statContribution(
          newMatch.homeScore!,
          newMatch.awayScore!,
          sign: 1,
        );
        homeDelta = homeDelta + apply.home;
        awayDelta = awayDelta + apply.away;
      }

      // Writes.
      txn.update(matchRef, {
        ...newMatch.toMap(),
        GNEsportMatch.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
      if (homeDelta.isNotEmpty) {
        txn.update(homeStatRef, _applyDeltaMap(homeStats, homeDelta));
      }
      if (awayDelta.isNotEmpty) {
        txn.update(awayStatRef, _applyDeltaMap(awayStats, awayDelta));
      }
    });
  }

  // create a custom match
  Future<void> createCustomMatch(GNEsportMatch match) async {
    final matchId = firestore
        .collection(
            '${GNEsportLeague.collectionName}/${match.leagueId}/${GNEsportMatch.collectionName}')
        .doc()
        .id;

    final matchWithId = match.copyWith(id: matchId);

    await firestore
        .collection(
            '${GNEsportLeague.collectionName}/${match.leagueId}/${GNEsportMatch.collectionName}')
        .doc(matchId)
        .set({
      ...matchWithId.toMap(),
      GNEsportMatch.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }

  /// Delete a match atomically. If the match was finished, reverses its
  /// stat contribution in the same transaction so totals stay consistent.
  Future<void> deleteMatch(GNEsportMatch match) async {
    final matchRef = firestore
        .collection(GNEsportLeague.collectionName)
        .doc(match.leagueId)
        .collection(GNEsportMatch.collectionName)
        .doc(match.id);

    final statRefs = await Future.wait([
      _statRefForUser(match.leagueId, match.homeTeamId),
      _statRefForUser(match.leagueId, match.awayTeamId),
    ]);
    final homeStatRef = statRefs[0];
    final awayStatRef = statRefs[1];

    await firestore.runTransaction((txn) async {
      final matchSnap = await txn.get(matchRef);
      if (!matchSnap.exists) {
        // Already deleted by someone else — nothing to do.
        return;
      }
      final current = GNEsportMatch.fromFirestore(matchSnap);

      if (current.isFinished &&
          current.homeScore != null &&
          current.awayScore != null) {
        final homeStatSnap = await txn.get(homeStatRef);
        final awayStatSnap = await txn.get(awayStatRef);
        final homeStats = GNEsportLeagueStat.fromFirestore(homeStatSnap);
        final awayStats = GNEsportLeagueStat.fromFirestore(awayStatSnap);

        final undo = _statContribution(
          current.homeScore!,
          current.awayScore!,
          sign: -1,
        );
        txn.update(homeStatRef, _applyDeltaMap(homeStats, undo.home));
        txn.update(awayStatRef, _applyDeltaMap(awayStats, undo.away));
      }

      txn.delete(matchRef);
    });
  }

  // --- Helpers --------------------------------------------------------------

  Future<DocumentReference<Map<String, dynamic>>> _statRefForUser(
    String leagueId,
    String userId,
  ) async {
    final snapshot = await firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportLeagueStat.collectionName)
        .where(GNEsportLeagueStat.fieldUserId, isEqualTo: userId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      throw Exception('No stats found for user $userId in league $leagueId');
    }
    return snapshot.docs.first.reference;
  }

  /// Compute one team's contribution (or undo, when sign = -1) to its stats
  /// for a single match outcome. Returns a delta keyed per stat field.
  _MatchStatPair _statContribution(int home, int away, {required int sign}) {
    final homeWin = home > away;
    final awayWin = away > home;
    final draw = home == away;
    return _MatchStatPair(
      home: _StatDelta(
        matchesPlayed: sign,
        goals: home * sign,
        goalsConceded: away * sign,
        wins: (homeWin ? 1 : 0) * sign,
        draws: (draw ? 1 : 0) * sign,
        losses: (awayWin ? 1 : 0) * sign,
      ),
      away: _StatDelta(
        matchesPlayed: sign,
        goals: away * sign,
        goalsConceded: home * sign,
        wins: (awayWin ? 1 : 0) * sign,
        draws: (draw ? 1 : 0) * sign,
        losses: (homeWin ? 1 : 0) * sign,
      ),
    );
  }

  Map<String, dynamic> _applyDeltaMap(
    GNEsportLeagueStat current,
    _StatDelta delta,
  ) {
    return {
      GNEsportLeagueStat.fieldMatchesPlayed:
          current.matchesPlayed + delta.matchesPlayed,
      GNEsportLeagueStat.fieldGoals: current.goals + delta.goals,
      GNEsportLeagueStat.fieldGoalsConceded:
          current.goalsConceded + delta.goalsConceded,
      GNEsportLeagueStat.fieldWins: current.wins + delta.wins,
      GNEsportLeagueStat.fieldDraws: current.draws + delta.draws,
      GNEsportLeagueStat.fieldLosses: current.losses + delta.losses,
    };
  }

  static const _zeroDelta = _StatDelta();
}

class _StatDelta {
  final int matchesPlayed;
  final int goals;
  final int goalsConceded;
  final int wins;
  final int draws;
  final int losses;

  const _StatDelta({
    this.matchesPlayed = 0,
    this.goals = 0,
    this.goalsConceded = 0,
    this.wins = 0,
    this.draws = 0,
    this.losses = 0,
  });

  bool get isNotEmpty =>
      matchesPlayed != 0 ||
      goals != 0 ||
      goalsConceded != 0 ||
      wins != 0 ||
      draws != 0 ||
      losses != 0;

  _StatDelta operator +(_StatDelta other) => _StatDelta(
        matchesPlayed: matchesPlayed + other.matchesPlayed,
        goals: goals + other.goals,
        goalsConceded: goalsConceded + other.goalsConceded,
        wins: wins + other.wins,
        draws: draws + other.draws,
        losses: losses + other.losses,
      );
}

class _MatchStatPair {
  final _StatDelta home;
  final _StatDelta away;
  const _MatchStatPair({required this.home, required this.away});
}
