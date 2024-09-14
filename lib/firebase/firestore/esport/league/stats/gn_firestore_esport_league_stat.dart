import 'package:game_note/firebase/firestore/gn_firestore.dart';

import 'gn_esport_league_stat.dart';

extension GNFirestoreEsportLeagueStat on GNFirestore {
  // create a stat for a user in a league
  Future<void> addLeagueStat({
    required String userId,
    required String leagueId,
  }) async {
    final leagueStatCollection =
        firestore.collection(GNEsportLeagueStat.collectionName);

    final newLeagueStat = GNEsportLeagueStat(
      id: leagueStatCollection.doc().id,
      userId: userId,
      matchesPlayed: 0,
      goals: 0,
      goalsConceded: 0,
      wins: 0,
      draws: 0,
      losses: 0,
    );

    await leagueStatCollection.doc(newLeagueStat.id).set(newLeagueStat.toMap());
  }
}
