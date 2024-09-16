import 'package:game_note/firebase/firestore/gn_firestore.dart';
import 'package:game_note/firebase/firestore/user/gn_firestore_user.dart';

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
    for (final doc in snapshot.docs) {
      final stats = GNEsportLeagueStat.fromFirestore(doc);
      // get user of the stat
      final user = await getUserById(stats.userId);
      leagues.add(stats.copyWith(user: user));
    }
    return leagues;
  }

  // TODO: - update a league stat
}
