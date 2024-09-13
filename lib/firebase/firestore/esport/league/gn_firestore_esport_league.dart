import 'package:game_note/firebase/firestore/gn_firestore.dart';

import 'gn_esport_league.dart';

extension GNFirestoreEsportLeague on GNFirestore {
  Future<List<GNEsportLeague>> getLeagues() async {
    final snapshot =
        await firestore.collection(GNEsportLeague.collectionName).get();
    final leagues =
        snapshot.docs.map((doc) => GNEsportLeague.fromFirestore(doc)).toList();
    leagues.sort((a, b) => b.startDate.compareTo(a.startDate));
    return leagues;
  }

  Future<GNEsportLeague?> getLeague(String leagueId) async {
    final snapshot = await firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .get();
    return snapshot.exists ? GNEsportLeague.fromFirestore(snapshot) : null;
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
      groupId: groupId, // Group ID
      name: name,
      startDate: startDate ?? DateTime.now(), // Default start date is now
      endDate: endDate ?? DateTime.now(), // Default end date is now
      isFinished: false, // League is not finished by default
      description: description,
    );

    // Add the new league to Firestore
    await leaguesCollection.doc(newLeague.id).set(newLeague.toMap());
  }
}
