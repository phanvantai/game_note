import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:game_note/firebase/firestore/esport/league/match/gn_esport_match.dart';
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

  // - update a league stats
  Future<void> updateLeagueStatWithMatch(GNEsportMatch match) async {
    final homeTeamStats =
        await getStatsWithUserId(match.leagueId, match.homeTeamId);
    final awayTeamStats =
        await getStatsWithUserId(match.leagueId, match.awayTeamId);

    // calculate new stats
    final homeWin = match.homeScore > match.awayScore;
    final awayWin = match.awayScore > match.homeScore;
    final draw = match.homeScore == match.awayScore;

    // update home team stats
    final updatedHomeStats = homeTeamStats.copyWith(
      matchesPlayed: homeTeamStats.matchesPlayed + 1,
      goals: homeTeamStats.goals + match.homeScore,
      goalsConceded: homeTeamStats.goalsConceded + match.awayScore,
      wins: homeTeamStats.wins + (homeWin ? 1 : 0),
      draws: homeTeamStats.draws + (draw ? 1 : 0),
      losses: homeTeamStats.losses + (awayWin ? 1 : 0),
    );

    // update away team stats
    final updatedAwayStats = awayTeamStats.copyWith(
      matchesPlayed: awayTeamStats.matchesPlayed + 1,
      goals: awayTeamStats.goals + match.awayScore,
      goalsConceded: awayTeamStats.goalsConceded + match.homeScore,
      wins: awayTeamStats.wins + (awayWin ? 1 : 0),
      draws: awayTeamStats.draws + (draw ? 1 : 0),
      losses: awayTeamStats.losses + (homeWin ? 1 : 0),
    );

    // update stats in firestore
    await updateLeagueStat(updatedHomeStats);
    await updateLeagueStat(updatedAwayStats);
  }

  Future<void> updateLeagueStat(GNEsportLeagueStat stats) async {
    final leagueStatCollection = firestore
        .collection(GNEsportLeague.collectionName)
        .doc(stats.leagueId)
        .collection(GNEsportLeagueStat.collectionName);

    await leagueStatCollection
        .doc(stats.id)
        .set(stats.toMap(), SetOptions(merge: true));
  }

  Future<GNEsportLeagueStat> getStatsWithUserId(
      String leagueId, String userId) async {
    final snapshot = await firestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportLeagueStat.collectionName)
        .where(GNEsportLeagueStat.fieldUserId, isEqualTo: userId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      final stats = GNEsportLeagueStat.fromFirestore(doc);
      // get user of the stat
      final user = await getUserById(stats.userId);
      return stats.copyWith(user: user);
    } else {
      throw Exception('No stats found for user with id $userId');
    }
  }

  // revert stats for a match
  Future<void> reverseStateWithMatch(GNEsportMatch math) async {
    final homeTeamStats =
        await getStatsWithUserId(math.leagueId, math.homeTeamId);
    final awayTeamStats =
        await getStatsWithUserId(math.leagueId, math.awayTeamId);

    // calculate new stats
    final homeWin = math.homeScore > math.awayScore;
    final awayWin = math.awayScore > math.homeScore;
    final draw = math.homeScore == math.awayScore;

    // update home team stats
    final updatedHomeStats = homeTeamStats.copyWith(
      matchesPlayed: homeTeamStats.matchesPlayed - 1,
      goals: homeTeamStats.goals - math.homeScore,
      goalsConceded: homeTeamStats.goalsConceded - math.awayScore,
      wins: homeTeamStats.wins - (homeWin ? 1 : 0),
      draws: homeTeamStats.draws - (draw ? 1 : 0),
      losses: homeTeamStats.losses - (awayWin ? 1 : 0),
    );

    // update away team stats
    final updatedAwayStats = awayTeamStats.copyWith(
      matchesPlayed: awayTeamStats.matchesPlayed - 1,
      goals: awayTeamStats.goals - math.awayScore,
      goalsConceded: awayTeamStats.goalsConceded - math.homeScore,
      wins: awayTeamStats.wins - (awayWin ? 1 : 0),
      draws: awayTeamStats.draws - (draw ? 1 : 0),
      losses: awayTeamStats.losses - (homeWin ? 1 : 0),
    );

    // update stats in firestore
    await updateLeagueStat(updatedHomeStats);
    await updateLeagueStat(updatedAwayStats);
  }
}
