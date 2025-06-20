import 'package:game_note/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:game_note/firebase/firestore/esport/league/stats/gn_firestore_esport_league_stat.dart';
import 'package:game_note/firebase/firestore/gn_firestore.dart';
import 'package:game_note/firebase/firestore/user/gn_firestore_user.dart';

import 'gn_esport_match.dart';

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

  // update medal of a match
  Future<void> updateMatchMedal({
    required String matchId,
    required String leagueId,
    int? medals,
  }) async {
    // Get the match document reference
    final matchRef = await firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportMatch.collectionName)
        .doc(matchId)
        .get();
    if (!matchRef.exists) {
      throw Exception('Match not found');
    }

    await matchRef.reference.update({GNEsportMatch.fieldMedals: medals});
  }

  // update a match
  Future<void> updateMatch({
    required String matchId,
    required String leagueId,
    int? homeScore,
    int? awayScore,
    int? medals,
  }) async {
    // Get the match document reference
    final matchRef = await firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportMatch.collectionName)
        .doc(matchId)
        .get();
    if (!matchRef.exists) {
      throw Exception('Match not found');
    }

    final match = GNEsportMatch.fromFirestore(matchRef);

    // check if match is finished
    if (match.isFinished) {
      // with finished match, need to revert the stats first, then update match score and update the stats again

      // reverse stats
      await reverseStateWithMatch(match);
    }

    // update match score and set match as finished
    GNEsportMatch newMatch = match.copyWith(
      homeScore: homeScore,
      awayScore: awayScore,
      isFinished: homeScore != null && awayScore != null,
      medals: medals,
    );

    await matchRef.reference.update(newMatch.toMap());

    // update stats
    if (newMatch.isFinished) {
      await updateLeagueStatWithMatch(newMatch);
    }
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
        .set(matchWithId.toMap());
  }

  Future<void> deleteMatch(GNEsportMatch match) async {
    // Get the match document reference
    final matchRef = await firestore
        .collection(GNEsportLeague.collectionName)
        .doc(match.leagueId)
        .collection(GNEsportMatch.collectionName)
        .doc(match.id)
        .get();
    if (!matchRef.exists) {
      throw Exception('Match not found');
    }

    // check if match is finished
    if (match.isFinished) {
      // with finished match, need to revert the stats first, then update match score and update the stats again

      // reverse stats
      await reverseStateWithMatch(match);
    }

    // delete match
    await matchRef.reference.delete();
  }
}
