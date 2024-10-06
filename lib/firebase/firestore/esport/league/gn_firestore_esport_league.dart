import 'package:firebase_auth/firebase_auth.dart';
import 'package:game_note/firebase/firestore/esport/group/gn_firestore_esport_group.dart';
import 'package:game_note/firebase/firestore/esport/league/stats/gn_firestore_esport_league_stat.dart';
import 'package:game_note/firebase/firestore/gn_firestore.dart';

import 'gn_esport_league.dart';

extension GNFirestoreEsportLeague on GNFirestore {
  Future<List<GNEsportLeague>> getLeagues() async {
    final snapshot = await firestore
        .collection(GNEsportLeague.collectionName)
        .where(GNEsportLeague.fieldIsActive, isEqualTo: true)
        .get();

    List<GNEsportLeague> leagues = [];
    for (final doc in snapshot.docs) {
      final league = GNEsportLeague.fromFirestore(doc);
      final group = await getGroupById(league.groupId);
      leagues.add(league.copyWith(group: group));
    }
    leagues.sort((a, b) => b.startDate.compareTo(a.startDate));
    return leagues;
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

  Future<void> addLeague({
    required String name,
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
    String description = '',
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
    );

    // Add the new league to Firestore
    await leaguesCollection.doc(newLeague.id).set(newLeague.toMap());
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

  // Update starting medals for a league
  Future<void> updateStartingMedals(String leagueId, int startingMedals) async {
    final leagueRef =
        firestore.collection(GNEsportLeague.collectionName).doc(leagueId);
    await leagueRef
        .update({GNEsportLeague.fieldStartingMedals: startingMedals});
  }

  // Update unit medals for a league
  Future<void> updateUnitMedals(String leagueId, int valueMedal) async {
    final leagueRef =
        firestore.collection(GNEsportLeague.collectionName).doc(leagueId);
    await leagueRef.update({GNEsportLeague.fieldValueMedal: valueMedal});
  }

  // listen for league updated
  Stream<GNEsportLeague> listenForLeagueUpdated(String leagueId) {
    return firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .snapshots()
        .map((snapshot) => GNEsportLeague.fromFirestore(snapshot));
  }

  // listen for leagues updated
  Stream<List<GNEsportLeague>> listenForLeaguesUpdated() {
    return firestore
        .collection(GNEsportLeague.collectionName)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GNEsportLeague.fromFirestore(doc))
          .toList();
    });
  }
}
