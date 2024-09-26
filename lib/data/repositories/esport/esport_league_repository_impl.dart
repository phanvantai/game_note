import 'package:game_note/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:game_note/firebase/firestore/esport/league/gn_firestore_esport_league.dart';
import 'package:game_note/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:game_note/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart';
import 'package:game_note/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:game_note/firebase/firestore/esport/league/stats/gn_firestore_esport_league_stat.dart';
import 'package:game_note/injection_container.dart';

import '../../../domain/repositories/esport/esport_league_repository.dart';
import '../../../firebase/firestore/gn_firestore.dart';

class EsportLeagueRepositoryImpl implements EsportLeagueRepository {
  @override
  Future<void> addLeague({
    required String name,
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
    String description = '',
  }) {
    return getIt<GNFirestore>().addLeague(
      name: name,
      groupId: groupId,
      startDate: startDate,
      endDate: endDate,
      description: description,
    );
  }

  @override
  Future<GNEsportLeague?> getLeague(String leagueId) {
    return getIt<GNFirestore>().getLeague(leagueId);
  }

  @override
  Future<List<GNEsportLeague>> getLeagues() {
    return getIt<GNFirestore>().getLeagues();
  }

  @override
  Future<List<GNEsportLeagueStat>> getLeagueStats(String leagueId) {
    return getIt<GNFirestore>().getLeagueStats(leagueId);
  }

  @override
  Future<void> addParticipant(
      {required String leagueId, required String userId}) {
    return getIt<GNFirestore>().addParticipantToLeague(leagueId, userId);
  }

  @override
  Future<void> generateRound(
      {required String leagueId, required List<String> teamIds}) {
    return getIt<GNFirestore>()
        .generateRound(leagueId: leagueId, teamIds: teamIds);
  }

  @override
  Future<List<GNEsportMatch>> getMatches(String leagueId) {
    return getIt<GNFirestore>().getMatches(leagueId);
  }

  @override
  Future<void> updateMatch(GNEsportMatch match) {
    return getIt<GNFirestore>().updateMatch(
      matchId: match.id,
      leagueId: match.leagueId,
      homeScore: match.homeScore,
      awayScore: match.awayScore,
    );
  }

  @override
  Future<void> updateLeague(GNEsportLeague league) {
    return getIt<GNFirestore>().updateLeague(league);
  }

  @override
  Future<void> inactiveLeague(GNEsportLeague league) {
    return getIt<GNFirestore>().inactiveLeague(league);
  }

  @override
  Future<void> deleteMatch(GNEsportMatch match) {
    return getIt<GNFirestore>().deleteMatch(match);
  }

  @override
  Future<void> createCustomMatch(GNEsportMatch match) {
    return getIt<GNFirestore>().createCustomMatch(match);
  }
}
