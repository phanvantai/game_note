import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_firestore_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_firestore_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';

import 'gn_esport_league.dart';

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
  /// Fetch leagues the current user owns OR participates in.
  ///
  /// Server-side filtered via two parallel queries (Firestore can't OR across
  /// different fields with a single query). Results are merged + deduped by
  /// id, then sorted by startDate desc.
  ///
  /// No pagination: a single user typically participates in tens of leagues
  /// at most, and pagination across two merged cursors gets messy. Revisit
  /// if a user reports slowness here.
  Future<List<GNEsportLeague>> getMyLeagues() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final col = firestore.collection(GNEsportLeague.collectionName);
    final ownedQuery = col
        .where(GNEsportLeague.fieldIsActive, isEqualTo: true)
        .where(GNEsportLeague.fieldOwnerId, isEqualTo: uid)
        .orderBy(GNEsportLeague.fieldStartDate, descending: true);
    final joinedQuery = col
        .where(GNEsportLeague.fieldIsActive, isEqualTo: true)
        .where(GNEsportLeague.fieldParticipants, arrayContains: uid)
        .orderBy(GNEsportLeague.fieldStartDate, descending: true);

    final snapshots = await Future.wait([ownedQuery.get(), joinedQuery.get()]);

    // Dedupe by id — a user can both own and participate in a league.
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

  Future<List<GNEsportLeague>> _attachGroups(
    List<GNEsportLeague> leagues,
  ) async {
    if (leagues.isEmpty) return leagues;
    final groupIds = leagues.map((l) => l.groupId).toSet().toList();
    final groupsMap = await getGroupsById(groupIds);
    return leagues
        .map((l) => l.copyWith(group: groupsMap[l.groupId]))
        .toList();
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
    String? status,
  }) async {
    // Reference to the Firestore collection
    final leaguesCollection =
        firestore.collection(GNEsportLeague.collectionName);

    // Create a new league with default and provided values
    final newLeague = GNEsportLeague(
      id: leaguesCollection.doc().id, // Generate a unique ID
      ownerId: FirebaseAuth.instance.currentUser?.uid ?? '', // Current user ID
      groupId: groupId, // Group ID
      name: name,
      startDate: startDate ?? DateTime.now(), // Default start date is now
      endDate: endDate ?? DateTime.now(), // Default end date is now
      isActive: true, // League is active by default
      description: description,
      participants: const [], // Empty list of participants
      rankPayoutEnabled: rankPayoutEnabled,
      rankPayouts: rankPayouts,
      defaultMatchCost: defaultMatchCost,
      status: status,
    );

    // Add the new league to Firestore
    await leaguesCollection.doc(newLeague.id).set(newLeague.toMap());
    return newLeague.id;
  }

  Future<void> addParticipantToLeague(
      String leagueId, String participantId) async {
    final leagueRef =
        firestore.collection(GNEsportLeague.collectionName).doc(leagueId);
    final leagueSnapshot = await leagueRef.get();
    if (!leagueSnapshot.exists) {
      throw Exception('League not found');
    }

    final league = GNEsportLeague.fromFirestore(leagueSnapshot);
    final updatedParticipants = List<String>.from(league.participants)
      ..add(participantId);
    await leagueRef
        .update({GNEsportLeague.fieldParticipants: updatedParticipants});

    // Add a new league stat for the participant
    await addLeagueStat(userId: participantId, leagueId: leagueId);
  }

  Future<void> addMultipleParticipantsToLeague(
      String leagueId, List<String> participantIds) async {
    final leagueRef =
        firestore.collection(GNEsportLeague.collectionName).doc(leagueId);
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
    
    await leagueRef
        .update({GNEsportLeague.fieldParticipants: updatedParticipants});

    // Add league stats for all new participants
    for (final participantId in participantIds) {
      if (!league.participants.contains(participantId)) {
        await addLeagueStat(userId: participantId, leagueId: leagueId);
      }
    }
  }

  Future<void> updateLeague(GNEsportLeague league) async {
    final leagueRef =
        firestore.collection(GNEsportLeague.collectionName).doc(league.id);
    await leagueRef.update(league.toMap());
  }

  Future<void> inactiveLeague(GNEsportLeague league) async {
    final leagueRef =
        firestore.collection(GNEsportLeague.collectionName).doc(league.id);
    await leagueRef.update({GNEsportLeague.fieldIsActive: false});
  }

  // listen for league updated
  Stream<GNEsportLeague> listenForLeagueUpdated(String leagueId) {
    return firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .snapshots()
        .map((snapshot) => GNEsportLeague.fromFirestore(snapshot));
  }

}
