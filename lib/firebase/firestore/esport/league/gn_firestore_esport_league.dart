import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_firestore_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_firestore_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';

import 'gn_esport_league.dart';
import 'match/gn_esport_match.dart';
import 'stats/gn_esport_league_stat.dart';

/// Paginated page of leagues with cursor info for infinite scroll.
class LeaguesPage {
  final List<GNEsportLeague> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const LeaguesPage({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
  });

  static const empty = LeaguesPage(items: [], lastDoc: null, hasMore: false);
}

extension GNFirestoreEsportLeague on GNFirestore {
  /// Fetch leagues the current user participates in as a player.
  ///
  /// Intentionally excludes leagues owned but not joined — those belong in a
  /// separate "management" flow (see profile). This keeps the count consistent
  /// with the dashboard stat (tournamentsJoined via Cloud Function).
  Future<LeaguesPage> getMyLeagues({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return LeaguesPage.empty;

    Query<Map<String, dynamic>> query = firestore
        .collection(GNEsportLeague.collectionName)
        .where(GNEsportLeague.fieldIsActive, isEqualTo: true)
        .where(GNEsportLeague.fieldParticipants, arrayContains: uid)
        .orderBy(GNEsportLeague.fieldStartDate, descending: true);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snap = await query.limit(limit + 1).get();
    final hasMore = snap.docs.length > limit;
    final docs = hasMore ? snap.docs.take(limit).toList() : snap.docs;
    final leagues = await _attachGroups(
      docs.map((d) => GNEsportLeague.fromFirestore(d)).toList(),
    );
    return LeaguesPage(
      items: leagues,
      lastDoc: docs.isNotEmpty ? docs.last : null,
      hasMore: hasMore,
    );
  }

  Future<LeaguesPage> getManagedLeagues({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return LeaguesPage.empty;

    Query<Map<String, dynamic>> query = firestore
        .collection(GNEsportLeague.collectionName)
        .where(GNEsportLeague.fieldIsActive, isEqualTo: true)
        .where(GNEsportLeague.fieldOwnerId, isEqualTo: uid)
        .orderBy(GNEsportLeague.fieldStartDate, descending: true);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final snap = await query.limit(limit + 1).get();
    final hasMore = snap.docs.length > limit;
    final docs = hasMore ? snap.docs.take(limit).toList() : snap.docs;
    final leagues = await _attachGroups(
      docs.map((d) => GNEsportLeague.fromFirestore(d)).toList(),
    );
    return LeaguesPage(
      items: leagues,
      lastDoc: docs.isNotEmpty ? docs.last : null,
      hasMore: hasMore,
    );
  }

  Future<List<GNEsportLeague>> getLeaguesByOwnerId(String ownerId) async {
    final snap = await firestore
        .collection(GNEsportLeague.collectionName)
        .where(GNEsportLeague.fieldIsActive, isEqualTo: true)
        .where(GNEsportLeague.fieldOwnerId, isEqualTo: ownerId)
        .orderBy(GNEsportLeague.fieldStartDate, descending: true)
        .get();
    final leagues = snap.docs.map(GNEsportLeague.fromFirestore).toList();
    return _attachGroups(leagues);
  }

  Future<void> transferLeagueOwnership({
    required String leagueId,
    required String newOwnerId,
  }) async {
    await firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .update({GNEsportLeague.fieldOwnerId: newOwnerId});
  }

  /// Fetch leagues the current user does NOT participate in. Paginated.
  ///
  /// Firestore can't express "NOT participants array-contains uid" in a
  /// single query, so we over-fetch and exclude client-side. To handle the
  /// case where most recent leagues belong to the user (filtered out, leaving
  /// the page near-empty), we loop internally fetching extra batches until
  /// we either reach `limit` items or run out of data. Bounded iterations
  /// to avoid pathological scans.
  Future<LeaguesPage> getOtherLeagues({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    const int batchSize = 25;
    const int maxIterations = 6; // hard cap: scan at most ~150 docs per page

    DocumentSnapshot? cursor = startAfter;
    final collected = <GNEsportLeague>[];
    bool sawEndOfCollection = false;

    for (int i = 0; i < maxIterations; i++) {
      Query<Map<String, dynamic>> query = firestore
          .collection(GNEsportLeague.collectionName)
          .where(GNEsportLeague.fieldIsActive, isEqualTo: true)
          .orderBy(GNEsportLeague.fieldStartDate, descending: true);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }
      final snapshot = await query.limit(batchSize).get();

      if (snapshot.docs.isEmpty) {
        sawEndOfCollection = true;
        break;
      }

      cursor = snapshot.docs.last;

      for (final doc in snapshot.docs) {
        final league = GNEsportLeague.fromFirestore(doc);
        if (uid != null &&
            (league.ownerId == uid || league.participants.contains(uid))) {
          continue;
        }
        collected.add(league);
      }

      if (collected.length >= limit) break;
      // Less than a full batch → no more docs after this.
      if (snapshot.docs.length < batchSize) {
        sawEndOfCollection = true;
        break;
      }
    }

    if (collected.isEmpty && cursor == null) {
      return LeaguesPage.empty;
    }

    final withGroups = await _attachGroups(collected);
    return LeaguesPage(
      items: withGroups,
      lastDoc: cursor,
      hasMore: !sawEndOfCollection,
    );
  }

  /// Fetch active leagues whose `groupId` is in the given list.
  ///
  /// Used by the home banner to surface ongoing tournaments from any group
  /// the user has joined — independent of whether they are a participant.
  /// Chunks `whereIn` queries (Firestore caps at 30 values per query) and
  /// dedupes by id.
  Future<List<GNEsportLeague>> getActiveLeaguesByGroupIds(
    List<String> groupIds,
  ) async {
    if (groupIds.isEmpty) return [];

    const chunkSize = 30;
    final col = firestore.collection(GNEsportLeague.collectionName);
    final futures = <Future<QuerySnapshot>>[];
    for (var i = 0; i < groupIds.length; i += chunkSize) {
      final chunk = groupIds.sublist(
        i,
        i + chunkSize > groupIds.length ? groupIds.length : i + chunkSize,
      );
      futures.add(
        col
            .where(GNEsportLeague.fieldIsActive, isEqualTo: true)
            .where(GNEsportLeague.fieldGroupId, whereIn: chunk)
            .get(),
      );
    }

    final snapshots = await Future.wait(futures);
    final byId = <String, GNEsportLeague>{};
    for (final snap in snapshots) {
      for (final doc in snap.docs) {
        byId[doc.id] = GNEsportLeague.fromFirestore(doc);
      }
    }

    final leagues = byId.values.toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
    return _attachGroups(leagues);
  }

  Future<List<GNEsportLeague>> _attachGroups(
    List<GNEsportLeague> leagues,
  ) async {
    if (leagues.isEmpty) return leagues;
    final groupIds = leagues.map((l) => l.groupId).toSet().toList();
    final groupsMap = await getGroupsById(groupIds);
    return leagues.map((l) => l.copyWith(group: groupsMap[l.groupId])).toList();
  }

  Future<GNEsportLeague?> getLeague(String leagueId) async {
    final snapshot = await firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .get();
    if (!snapshot.exists) {
      return null;
    }
    final league = GNEsportLeague.fromFirestore(snapshot);
    // Get the group that the league belongs to
    final group = await getGroupById(league.groupId);
    return league.copyWith(group: group);
  }

  Future<GNEsportLeague?> getLeagueByLeagueId(String leagueId) async {
    final snapshot = await firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .get();
    if (!snapshot.exists) {
      return null;
    }
    final league = GNEsportLeague.fromFirestore(snapshot);
    // Get the group that the league belongs to
    final group = await getGroupById(league.groupId);
    return league.copyWith(group: group);
  }

  /// Returns the id of the newly-created league. Older callers that ignored
  /// the result still work — Dart silently drops the return value.
  Future<String> addLeague({
    required String name,
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
    String description = '',
    bool rankPayoutEnabled = false,
    List<int> rankPayouts = const [],
    int defaultMatchCost = 50000,
    bool defaultPerGoalEnabled = false,
    int defaultCostPerGoal = 50000,
    String? status,
    TournamentMode mode = TournamentMode.league,
    int groupCount = 1,
    int advanceCount = 2,
    List<String> participants = const [],
    List<String> knockoutSeeding = const [],
  }) async {
    final leaguesCollection = firestore.collection(
      GNEsportLeague.collectionName,
    );

    final newLeague = GNEsportLeague(
      id: leaguesCollection.doc().id,
      ownerId: FirebaseAuth.instance.currentUser?.uid ?? '',
      groupId: groupId,
      name: name,
      startDate: startDate ?? DateTime.now(),
      endDate: endDate,
      isActive: true,
      description: description,
      participants: participants,
      rankPayoutEnabled: rankPayoutEnabled,
      rankPayouts: rankPayouts,
      defaultMatchCost: defaultMatchCost,
      defaultPerGoalEnabled: defaultPerGoalEnabled,
      defaultCostPerGoal: defaultCostPerGoal,
      status: status,
      mode: mode,
      groupCount: groupCount,
      advanceCount: advanceCount,
      knockoutSeeding: knockoutSeeding,
    );

    await leaguesCollection.doc(newLeague.id).set(newLeague.toMap());
    return newLeague.id;
  }

  Future<void> addParticipantToLeague(
    String leagueId,
    String participantId,
  ) async {
    final leagueRef = firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId);
    final leagueSnapshot = await leagueRef.get();
    if (!leagueSnapshot.exists) {
      throw Exception('League not found');
    }

    final league = GNEsportLeague.fromFirestore(leagueSnapshot);
    final updatedParticipants = List<String>.from(league.participants)
      ..add(participantId);
    await leagueRef.update({
      GNEsportLeague.fieldParticipants: updatedParticipants,
    });

    // Add a new league stat for the participant
    await addLeagueStat(userId: participantId, leagueId: leagueId);
  }

  Future<void> addMultipleParticipantsToLeague(
    String leagueId,
    List<String> participantIds,
  ) async {
    final leagueRef = firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId);
    final leagueSnapshot = await leagueRef.get();
    if (!leagueSnapshot.exists) {
      throw Exception('League not found');
    }

    final league = GNEsportLeague.fromFirestore(leagueSnapshot);
    final updatedParticipants = List<String>.from(league.participants);

    // Add participants that are not already in the league
    for (final participantId in participantIds) {
      if (!updatedParticipants.contains(participantId)) {
        updatedParticipants.add(participantId);
      }
    }

    await leagueRef.update({
      GNEsportLeague.fieldParticipants: updatedParticipants,
    });

    // Add league stats for all new participants
    for (final participantId in participantIds) {
      if (!league.participants.contains(participantId)) {
        await addLeagueStat(userId: participantId, leagueId: leagueId);
      }
    }
  }

  Future<void> updateLeague(GNEsportLeague league) async {
    final leagueRef = firestore
        .collection(GNEsportLeague.collectionName)
        .doc(league.id);
    await leagueRef.update(league.toMap());
  }

  Future<void> inactiveLeague(GNEsportLeague league) async {
    final leagueRef = firestore
        .collection(GNEsportLeague.collectionName)
        .doc(league.id);
    await leagueRef.update({GNEsportLeague.fieldIsActive: false});
  }

  Future<void> deleteLeague(String leagueId) async {
    await firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .delete();
  }

  // listen for league updated
  Stream<GNEsportLeague> listenForLeagueUpdated(String leagueId) {
    return firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .snapshots()
        .map((snapshot) => GNEsportLeague.fromFirestore(snapshot));
  }

  /// All leagues belonging to [groupId], including inactive/finished ones.
  /// Used by the group admin tab to manage participants across all leagues.
  Future<List<GNEsportLeague>> getLeaguesByGroupId(String groupId) async {
    final snap = await firestore
        .collection(GNEsportLeague.collectionName)
        .where(GNEsportLeague.fieldGroupId, isEqualTo: groupId)
        .where(GNEsportLeague.fieldIsActive, isEqualTo: true)
        .orderBy(GNEsportLeague.fieldStartDate, descending: true)
        .get();
    final leagues = snap.docs.map(GNEsportLeague.fromFirestore).toList();
    return _attachGroups(leagues);
  }

  /// Atomically replace [oldUserId] with [newUserId] inside [leagueId].
  ///
  /// If [newUserId] already has a stat doc in the league, their stats are
  /// merged (summed) and [oldUserId]'s stat doc is deleted. Otherwise the
  /// existing stat doc is reassigned to [newUserId].
  /// All match references (homeTeamId / awayTeamId) are updated in the same
  /// WriteBatch so the operation is atomic.
  Future<void> replaceParticipantInLeague({
    required String leagueId,
    required String oldUserId,
    required String newUserId,
  }) async {
    final leagueRef = firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId);
    final statsCol = leagueRef.collection(GNEsportLeagueStat.collectionName);
    final matchesCol = leagueRef.collection(GNEsportMatch.collectionName);

    // Fire all reads concurrently.
    final leagueSnapFuture = leagueRef.get();
    final oldStatFuture = statsCol
        .where(GNEsportLeagueStat.fieldUserId, isEqualTo: oldUserId)
        .limit(1)
        .get();
    final newStatFuture = statsCol
        .where(GNEsportLeagueStat.fieldUserId, isEqualTo: newUserId)
        .limit(1)
        .get();
    final matchesFuture = matchesCol.get();

    final leagueSnap = await leagueSnapFuture;
    if (!leagueSnap.exists) throw Exception('League not found: $leagueId');
    final league = GNEsportLeague.fromFirestore(leagueSnap);

    final oldStatQuery = await oldStatFuture;
    if (oldStatQuery.docs.isEmpty) {
      throw Exception('User $oldUserId not found in league $leagueId');
    }
    final oldStatDoc = oldStatQuery.docs.first;
    final oldStat = GNEsportLeagueStat.fromFirestore(oldStatDoc);

    final newStatQuery = await newStatFuture;
    final newStatDoc = newStatQuery.docs.isEmpty
        ? null
        : newStatQuery.docs.first;
    final newStat = newStatDoc != null
        ? GNEsportLeagueStat.fromFirestore(newStatDoc)
        : null;

    final matchDocs = (await matchesFuture).docs;

    // Build updated participants list.
    final updatedParticipants = List<String>.from(league.participants)
      ..remove(oldUserId);
    if (!updatedParticipants.contains(newUserId)) {
      updatedParticipants.add(newUserId);
    }

    final batch = firestore.batch();

    // 1. Update participants array.
    batch.update(leagueRef, {
      GNEsportLeague.fieldParticipants: updatedParticipants,
    });

    // 2. Handle stat docs.
    if (newStat == null) {
      // New user not yet in league — reassign the existing stat doc.
      batch.update(oldStatDoc.reference, {
        GNEsportLeagueStat.fieldUserId: newUserId,
      });
    } else {
      // New user already in league — merge totals into their doc, delete old.
      batch.update(newStatDoc!.reference, {
        GNEsportLeagueStat.fieldMatchesPlayed:
            newStat.matchesPlayed + oldStat.matchesPlayed,
        GNEsportLeagueStat.fieldGoals: newStat.goals + oldStat.goals,
        GNEsportLeagueStat.fieldGoalsConceded:
            newStat.goalsConceded + oldStat.goalsConceded,
        GNEsportLeagueStat.fieldWins: newStat.wins + oldStat.wins,
        GNEsportLeagueStat.fieldDraws: newStat.draws + oldStat.draws,
        GNEsportLeagueStat.fieldLosses: newStat.losses + oldStat.losses,
      });
      batch.delete(oldStatDoc.reference);
    }

    // 3. Update matches that reference oldUserId.
    for (final matchDoc in matchDocs) {
      final data = matchDoc.data();
      final updates = <String, dynamic>{};
      if (data[GNEsportMatch.fieldHomeTeamId] == oldUserId) {
        updates[GNEsportMatch.fieldHomeTeamId] = newUserId;
      }
      if (data[GNEsportMatch.fieldAwayTeamId] == oldUserId) {
        updates[GNEsportMatch.fieldAwayTeamId] = newUserId;
      }
      if (updates.isNotEmpty) {
        batch.update(matchDoc.reference, updates);
      }
    }

    await batch.commit();
  }

  Future<void> setMergeCompleted(String leagueId, {required bool completed}) {
    return firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .update({GNEsportLeague.fieldMergeCompleted: completed});
  }
}
