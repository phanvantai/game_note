import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_firestore_esport_league_stat.dart';
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
    final matchPath =
        '${GNEsportLeague.collectionName}/$leagueId/${GNEsportMatch.collectionName}';
    final docs = <MapEntry<String, Map<String, dynamic>>>[];

    for (int i = 0; i < teamIds.length; i++) {
      for (int j = i + 1; j < teamIds.length; j++) {
        final matchId = firestore.collection(matchPath).doc().id;
        final match = GNEsportMatch(
          id: matchId,
          homeTeamId: teamIds[i],
          awayTeamId: teamIds[j],
          homeScore: 0,
          awayScore: 0,
          date: DateTime.now(),
          isFinished: false,
          leagueId: leagueId,
        );
        docs.add(MapEntry('$matchPath/$matchId', match.toMap()));
      }
    }

    // Stat docs before match docs: matches reference stats during score
    // entry via _statRefForUser; writing stats first means a partial stat
    // failure leaves no orphan matches behind. addMultipleParticipants
    // dedups stat creation against league.participants, which the create
    // flow has already populated — so the generator owns stats here.
    await Future.wait([
      for (final userId in teamIds)
        addLeagueStat(userId: userId, leagueId: leagueId),
    ]);
    await _writeBatched(docs);
  }

  /// Generate an additional round-robin round for a specific group in full mode.
  Future<void> generateGroupRound({
    required String leagueId,
    required String groupId,
    required List<String> teamIds,
  }) async {
    final matchPath =
        '${GNEsportLeague.collectionName}/$leagueId/${GNEsportMatch.collectionName}';
    final docs = <MapEntry<String, Map<String, dynamic>>>[];
    for (int i = 0; i < teamIds.length; i++) {
      for (int j = i + 1; j < teamIds.length; j++) {
        final matchId = firestore.collection(matchPath).doc().id;
        final match = GNEsportMatch(
          id: matchId,
          homeTeamId: teamIds[i],
          awayTeamId: teamIds[j],
          homeScore: 0,
          awayScore: 0,
          date: DateTime.now(),
          isFinished: false,
          leagueId: leagueId,
          phase: 'group',
          groupId: groupId,
        );
        docs.add(MapEntry('$matchPath/$matchId', match.toMap()));
      }
    }
    await _writeBatched(docs);
  }

  /// Generate a single-elimination knockout bracket.
  ///
  /// [seededTeamIds] must have a length that is a power of 2 (2, 4, 8, 16…).
  /// Throws [ArgumentError] otherwise.
  ///
  /// Bracket seeding: slot s in round 0 pairs seededTeamIds[s] vs
  /// seededTeamIds[N-1-s]. Winners advance via (round+1, slot÷2); even slots
  /// become homeTeamId, odd slots become awayTeamId in the next match.
  Future<void> generateCupBracket({
    required String leagueId,
    required List<String> seededTeamIds,
  }) async {
    final n = seededTeamIds.length;
    if (n < 2 || (n & (n - 1)) != 0) {
      throw ArgumentError(
        'Cup bracket requires a power-of-2 participant count, got $n',
      );
    }
    final totalRounds = (math.log(n) / math.log(2)).round();
    final r0SlotCount = n ~/ 2;
    final matchPath =
        '${GNEsportLeague.collectionName}/$leagueId/${GNEsportMatch.collectionName}';

    // Pre-generate all doc IDs for all rounds so we can set nextMatchId.
    // roundIds[r] = list of match IDs for round r.
    final List<List<String>> roundIds = List.generate(
      totalRounds,
      (r) => List.generate(
        r0SlotCount >> r,
        (_) => firestore.collection(matchPath).doc().id,
      ),
    );

    final docs = <MapEntry<String, Map<String, dynamic>>>[];

    for (int r = 0; r < totalRounds; r++) {
      final slotsInRound = r0SlotCount >> r;
      for (int s = 0; s < slotsInRound; s++) {
        final matchId = roundIds[r][s];
        final nextMatchId =
            r < totalRounds - 1 ? roundIds[r + 1][s ~/ 2] : null;

        final String homeId;
        final String awayId;
        if (r == 0) {
          homeId = seededTeamIds[s];
          awayId = seededTeamIds[n - 1 - s];
        } else {
          homeId = '';
          awayId = '';
        }

        final match = GNEsportMatch(
          id: matchId,
          homeTeamId: homeId,
          awayTeamId: awayId,
          homeScore: 0,
          awayScore: 0,
          date: DateTime.now(),
          isFinished: false,
          leagueId: leagueId,
          phase: 'knockout',
          knockoutRound: r,
          knockoutSlot: s,
          nextMatchId: nextMatchId,
        );

        docs.add(MapEntry('$matchPath/$matchId', match.toMap()));
      }
    }

    await _writeBatched(docs);
  }

  /// Generate a full-tournament: group stage (round-robin per group) +
  /// an empty knockout bracket for the advancing players.
  ///
  /// [groups] is a list of player-ID lists, one per group (A, B, …).
  /// The knockout bracket has groups.length × [advanceCount] slots,
  /// which must be a power of 2.
  Future<void> generateFullTournament({
    required String leagueId,
    required List<List<String>> groups,
    required int advanceCount,
    List<String> knockoutSeeding = const [],
  }) async {
    final knockoutSize = groups.length * advanceCount;
    if (knockoutSize < 2 || (knockoutSize & (knockoutSize - 1)) != 0) {
      throw ArgumentError(
        'Knockout size (groupCount × advanceCount = $knockoutSize) '
        'must be a power of 2',
      );
    }
    final matchPath =
        '${GNEsportLeague.collectionName}/$leagueId/${GNEsportMatch.collectionName}';

    // --- Group stage ---
    final groupLabels = List.generate(
      groups.length,
      (i) => String.fromCharCode('A'.codeUnitAt(0) + i),
    );

    // Stat docs first: if stat creation fails we haven't written any matches,
    // so there is no partial state to clean up.
    final statFutures = <Future<void>>[];
    final docs = <MapEntry<String, Map<String, dynamic>>>[];

    for (int g = 0; g < groups.length; g++) {
      final groupId = groupLabels[g];
      final groupMembers = groups[g];
      for (final memberId in groupMembers) {
        statFutures.add(
          addLeagueStat(userId: memberId, leagueId: leagueId, groupId: groupId),
        );
      }
      for (int i = 0; i < groupMembers.length; i++) {
        for (int j = i + 1; j < groupMembers.length; j++) {
          final matchId = firestore.collection(matchPath).doc().id;
          final match = GNEsportMatch(
            id: matchId,
            homeTeamId: groupMembers[i],
            awayTeamId: groupMembers[j],
            homeScore: 0,
            awayScore: 0,
            date: DateTime.now(),
            isFinished: false,
            leagueId: leagueId,
            phase: 'group',
            groupId: groupId,
          );
          docs.add(MapEntry('$matchPath/$matchId', match.toMap()));
        }
      }
    }

    // --- Knockout bracket skeleton (all TBD) ---
    final totalRounds = (math.log(knockoutSize) / math.log(2)).round();
    final r0SlotCount = knockoutSize ~/ 2;
    final List<List<String>> roundIds = List.generate(
      totalRounds,
      (r) => List.generate(
        r0SlotCount >> r,
        (_) => firestore.collection(matchPath).doc().id,
      ),
    );

    final useSeeding =
        knockoutSeeding.length == knockoutSize && knockoutSize >= 2;
    for (int r = 0; r < totalRounds; r++) {
      final slotsInRound = r0SlotCount >> r;
      for (int s = 0; s < slotsInRound; s++) {
        final matchId = roundIds[r][s];
        final nextMatchId =
            r < totalRounds - 1 ? roundIds[r + 1][s ~/ 2] : null;
        final String homeId;
        final String awayId;
        if (r == 0 && useSeeding) {
          homeId = knockoutSeeding[s];
          awayId = knockoutSeeding[knockoutSize - 1 - s];
        } else {
          homeId = '';
          awayId = '';
        }
        final match = GNEsportMatch(
          id: matchId,
          homeTeamId: homeId,
          awayTeamId: awayId,
          homeScore: 0,
          awayScore: 0,
          date: DateTime.now(),
          isFinished: false,
          leagueId: leagueId,
          phase: 'knockout',
          knockoutRound: r,
          knockoutSlot: s,
          nextMatchId: nextMatchId,
        );
        docs.add(MapEntry('$matchPath/$matchId', match.toMap()));
      }
    }

    // Stat docs before match docs: if stats fail, no matches are written.
    await Future.wait(statFutures);
    await _writeBatched(docs);
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
      if (match.homeTeamId.isNotEmpty) userIds.add(match.homeTeamId);
      if (match.awayTeamId.isNotEmpty) userIds.add(match.awayTeamId);
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

  /// Update a match's score/cost. Writes the match doc only — stat docs are
  /// NOT touched here. Callers must follow up with [applyMatchStatDelta]
  /// (typically fire-and-forget from the bloc) to keep player stats in sync.
  ///
  /// Returns the match state before and after the write so the caller can
  /// compute the delta without re-reading.
  ///
  /// Knockout matches: this still atomically advances the winner into the
  /// next bracket slot — that's structural data the user expects to see
  /// immediately and which has nothing to do with player stats.
  ///
  /// [expectedUpdatedAt] — if provided, throws [ConcurrentMatchUpdateException]
  /// when the stored `updatedAt` differs (optimistic-lock).
  Future<({GNEsportMatch previous, GNEsportMatch updated})> updateMatch({
    required String matchId,
    required String leagueId,
    int? homeScore,
    int? awayScore,
    int? matchCost,
    Timestamp? expectedUpdatedAt,
  }) async {
    final matchPath =
        '${GNEsportLeague.collectionName}/$leagueId/${GNEsportMatch.collectionName}';
    final matchRef = firestore.doc('$matchPath/$matchId');

    late GNEsportMatch previous;
    late GNEsportMatch updated;

    await firestore.runTransaction((txn) async {
      final matchSnap = await txn.get(matchRef);
      if (!matchSnap.exists) throw Exception('Match not found');
      final current = GNEsportMatch.fromFirestore(matchSnap);

      if (expectedUpdatedAt != null &&
          current.updatedAt != null &&
          current.updatedAt != expectedUpdatedAt) {
        throw ConcurrentMatchUpdateException(matchId);
      }

      final newMatch = current.copyWith(
        homeScore: homeScore,
        awayScore: awayScore,
        isFinished: homeScore != null && awayScore != null,
        matchCost: matchCost ?? current.matchCost,
      );

      previous = current;
      updated = newMatch;

      txn.update(matchRef, {
        ...newMatch.toMap(),
        GNEsportMatch.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });

      // Knockout winner advancement stays here — it's not a stat update,
      // it's bracket structure that must move atomically with the score.
      final isKnockout = current.phase == 'knockout';
      if (isKnockout && newMatch.isFinished && current.nextMatchId != null) {
        final nextRef = firestore.doc('$matchPath/${current.nextMatchId}');
        final winnerId = newMatch.homeScore! >= newMatch.awayScore!
            ? current.homeTeamId
            : current.awayTeamId;
        final isEvenSlot = (current.knockoutSlot ?? 0).isEven;
        txn.update(nextRef, {
          isEvenSlot
              ? GNEsportMatch.fieldHomeTeamId
              : GNEsportMatch.fieldAwayTeamId: winnerId,
        });
      }
    });

    return (previous: previous, updated: updated);
  }

  /// Apply a per-match stat delta — undoes [previous]'s contribution (if it
  /// was finished) and applies [updated]'s contribution (if it is). Designed
  /// to run asynchronously after [updateMatch] returns; the bloc fires this
  /// without awaiting so match save latency isn't penalised by stat I/O.
  ///
  /// No-op cases (silently):
  /// - Knockout matches (no stat tracking for bracket rounds).
  /// - Empty home/away IDs (TBD bracket slots before winners advance).
  /// - When delta is zero (e.g. only matchCost changed).
  ///
  /// Throws if a stat doc is missing for either player — the bloc swallows
  /// this so the user isn't blocked; the manual "đồng bộ điểm số" action
  /// reconciles drift via [recomputeLeagueStats].
  Future<void> applyMatchStatDelta({
    required GNEsportMatch previous,
    required GNEsportMatch updated,
  }) async {
    if (previous.phase == 'knockout') return;
    if (previous.homeTeamId.isEmpty || previous.awayTeamId.isEmpty) return;

    var homeDelta = _zeroDelta;
    var awayDelta = _zeroDelta;
    if (previous.isFinished &&
        previous.homeScore != null &&
        previous.awayScore != null) {
      final undo = _statContribution(
        previous.homeScore!,
        previous.awayScore!,
        sign: -1,
      );
      homeDelta = homeDelta + undo.home;
      awayDelta = awayDelta + undo.away;
    }
    if (updated.isFinished &&
        updated.homeScore != null &&
        updated.awayScore != null) {
      final apply = _statContribution(
        updated.homeScore!,
        updated.awayScore!,
        sign: 1,
      );
      homeDelta = homeDelta + apply.home;
      awayDelta = awayDelta + apply.away;
    }

    if (!homeDelta.isNotEmpty && !awayDelta.isNotEmpty) return;

    final refs = await Future.wait([
      _statRefForUser(previous.leagueId, previous.homeTeamId,
          groupId: previous.groupId),
      _statRefForUser(previous.leagueId, previous.awayTeamId,
          groupId: previous.groupId),
    ]);
    final homeStatRef = refs[0];
    final awayStatRef = refs[1];

    await firestore.runTransaction((txn) async {
      final homeStatSnap = await txn.get(homeStatRef);
      final awayStatSnap = await txn.get(awayStatRef);
      final homeStats = GNEsportLeagueStat.fromFirestore(homeStatSnap);
      final awayStats = GNEsportLeagueStat.fromFirestore(awayStatSnap);

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
      _statRefForUser(match.leagueId, match.homeTeamId, groupId: match.groupId),
      _statRefForUser(match.leagueId, match.awayTeamId, groupId: match.groupId),
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

  static const int _kBatchLimit = 499;

  /// Writes [docs] (path → data pairs) in chunks of [_kBatchLimit] to stay
  /// under Firestore's 500-write-per-batch ceiling.
  Future<void> _writeBatched(
    List<MapEntry<String, Map<String, dynamic>>> docs,
  ) async {
    for (int i = 0; i < docs.length; i += _kBatchLimit) {
      final end = (i + _kBatchLimit).clamp(0, docs.length);
      final batch = firestore.batch();
      for (final entry in docs.sublist(i, end)) {
        batch.set(firestore.doc(entry.key), entry.value);
      }
      await batch.commit();
    }
  }

  Future<DocumentReference<Map<String, dynamic>>> _statRefForUser(
    String leagueId,
    String userId, {
    String? groupId,
  }) async {
    // Filter groupId in code rather than via `isNull: true`, because
    // GNEsportLeagueStat.toMap omits the field entirely when groupId is null
    // (league-wide stats). Firestore's isNull predicate only matches docs
    // where the field exists with value null — it does NOT match docs where
    // the field is absent — so an isNull query against league-wide stats
    // would silently miss every legacy doc and throw "No stats found" on
    // every match update.
    final snapshot = await firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportLeagueStat.collectionName)
        .where(GNEsportLeagueStat.fieldUserId, isEqualTo: userId)
        .get();
    final match = snapshot.docs.where((doc) {
      final docGroupId = doc.data()[GNEsportLeagueStat.fieldGroupId] as String?;
      return docGroupId == groupId;
    }).toList();
    if (match.isEmpty) {
      throw Exception(
        'No stats found for user $userId in league $leagueId'
        '${groupId != null ? " group $groupId" : ""}',
      );
    }
    return match.first.reference;
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
