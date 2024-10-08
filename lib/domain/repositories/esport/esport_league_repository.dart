import 'package:game_note/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:game_note/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';

import '../../../firebase/firestore/esport/league/gn_esport_league.dart';

abstract class EsportLeagueRepository {
  Future<List<GNEsportLeague>> getLeagues();

  Future<GNEsportLeague?> getLeague(String leagueId);

  Future<void> addLeague({
    required String name,
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
    String description = '',
  });

  Future<List<GNEsportLeagueStat>> getLeagueStats(String leagueId);

  Future<void> addParticipant({
    required String leagueId,
    required String userId,
  });

  Future<void> generateRound({
    required String leagueId,
    required List<String> teamIds,
  });

  Future<List<GNEsportMatch>> getMatches(String leagueId);
  Future<void> updateMatch(GNEsportMatch match);
  Future<void> updateLeague(GNEsportLeague league);
  Future<void> inactiveLeague(GNEsportLeague league);
  Future<void> deleteMatch(GNEsportMatch match);
  Future<void> createCustomMatch(GNEsportMatch match);
  Future<void> updateLeagueStartingMedals(String leagueId, int startingMedals);
  Future<void> updateLeagueUnitMedals(String leagueId, int unitMedals);

  Future<void> updateMatchMedals(String matchId, String leagueId, int medals);

  Stream<List<GNEsportLeagueStat>> listenForLeagueStats(String leagueId);
  Stream<List<GNEsportMatch>> listenForMatchesUpdated(String leagueId);
  Stream<GNEsportLeague> listenForLeagueUpdated(String leagueId);

  Stream<List<GNEsportLeague>> listenForLeagues();
}
