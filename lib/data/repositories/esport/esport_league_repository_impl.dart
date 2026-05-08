import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_firestore_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_firestore_esport_league_stat.dart';
import 'package:pes_arena/injection_container.dart';

import '../../../domain/repositories/esport/esport_league_repository.dart';
import '../../../firebase/firestore/gn_firestore.dart';

class EsportLeagueRepositoryImpl implements EsportLeagueRepository {
  @override
  Future<String> addLeague({
    required String name,
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
    String description = '',
    bool rankPayoutEnabled = false,
    List<int> rankPayouts = const [],
    int defaultMatchCost = 50000,
    TournamentMode mode = TournamentMode.league,
    int groupCount = 1,
    int advanceCount = 2,
    List<String> participants = const [],
    List<String> knockoutSeeding = const [],
  }) {
    return getIt<GNFirestore>().addLeague(
      name: name,
      groupId: groupId,
      startDate: startDate,
      endDate: endDate,
      description: description,
      rankPayoutEnabled: rankPayoutEnabled,
      rankPayouts: rankPayouts,
      defaultMatchCost: defaultMatchCost,
      mode: mode,
      groupCount: groupCount,
      advanceCount: advanceCount,
      participants: participants,
      knockoutSeeding: knockoutSeeding,
    );
  }

  @override
  Future<void> generateCupBracket({
    required String leagueId,
    required List<String> seededTeamIds,
  }) {
    return getIt<GNFirestore>().generateCupBracket(
      leagueId: leagueId,
      seededTeamIds: seededTeamIds,
    );
  }

  @override
  Future<void> generateFullTournament({
    required String leagueId,
    required List<List<String>> groups,
    required int advanceCount,
    List<String> knockoutSeeding = const [],
  }) {
    return getIt<GNFirestore>().generateFullTournament(
      leagueId: leagueId,
      groups: groups,
      advanceCount: advanceCount,
      knockoutSeeding: knockoutSeeding,
    );
  }

  @override
  Future<GNEsportLeague?> getLeague(String leagueId) {
    return getIt<GNFirestore>().getLeague(leagueId);
  }

  @override
  Future<List<GNEsportLeague>> getActiveLeaguesByGroupIds(
    List<String> groupIds,
  ) {
    return getIt<GNFirestore>().getActiveLeaguesByGroupIds(groupIds);
  }

  @override
  Future<LeaguesPage> getMyLeagues({Object? startAfter, int limit = 20}) {
    return getIt<GNFirestore>().getMyLeagues(
      startAfter: startAfter is DocumentSnapshot ? startAfter : null,
      limit: limit,
    );
  }

  @override
  Future<LeaguesPage> getManagedLeagues({Object? startAfter, int limit = 20}) {
    return getIt<GNFirestore>().getManagedLeagues(
      startAfter: startAfter is DocumentSnapshot ? startAfter : null,
      limit: limit,
    );
  }

  @override
  Future<LeaguesPage> getOtherLeagues({
    Object? startAfter,
    int limit = 20,
  }) {
    return getIt<GNFirestore>().getOtherLeagues(
      startAfter: startAfter is DocumentSnapshot ? startAfter : null,
      limit: limit,
    );
  }

  @override
  Future<List<GNEsportLeagueStat>> getLeagueStats(String leagueId) {
    return getIt<GNFirestore>().getLeagueStats(leagueId);
  }

  @override
  Future<Map<String, GNUser>> getUsersByIds(List<String> userIds) {
    return getIt<GNFirestore>().getUsersById(userIds);
  }

  @override
  Future<void> addParticipant(
      {required String leagueId, required String userId}) {
    return getIt<GNFirestore>().addParticipantToLeague(leagueId, userId);
  }

  @override
  Future<void> addMultipleParticipants(
      {required String leagueId, required List<String> userIds}) {
    return getIt<GNFirestore>().addMultipleParticipantsToLeague(leagueId, userIds);
  }

  @override
  Future<void> generateRound(
      {required String leagueId, required List<String> teamIds}) {
    return getIt<GNFirestore>()
        .generateRound(leagueId: leagueId, teamIds: teamIds);
  }

  @override
  Future<void> generateGroupRound({
    required String leagueId,
    required String groupId,
    required List<String> teamIds,
  }) {
    return getIt<GNFirestore>().generateGroupRound(
      leagueId: leagueId,
      groupId: groupId,
      teamIds: teamIds,
    );
  }

  @override
  Future<List<GNEsportMatch>> getMatches(String leagueId) {
    return getIt<GNFirestore>().getMatches(leagueId);
  }

  @override
  Future<void> updateMatch(GNEsportMatch match) {
    // The match instance the UI is submitting still carries the `updatedAt`
    // it had when the dialog opened — pass it down for the optimistic-lock
    // check inside the transaction.
    return getIt<GNFirestore>().updateMatch(
      matchId: match.id,
      leagueId: match.leagueId,
      homeScore: match.homeScore,
      awayScore: match.awayScore,
      matchCost: match.matchCost,
      expectedUpdatedAt: match.updatedAt,
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

  @override
  Future<void> recomputeLeagueStats(String leagueId) {
    return getIt<GNFirestore>().recomputeLeagueStats(leagueId);
  }

  @override
  Future<LeagueDetailData> getParticipantsAndMatches(String leagueId) async {
    // Load participants and matches in parallel to improve performance
    final results = await Future.wait([
      getIt<GNFirestore>().getLeagueStats(leagueId),
      getIt<GNFirestore>().getMatches(leagueId),
    ]);

    return LeagueDetailData(
      participants: results[0] as List<GNEsportLeagueStat>,
      matches: results[1] as List<GNEsportMatch>,
    );
  }

  @override
  Stream<List<GNEsportMatch>> listenForMatchesUpdated(String leagueId) {
    return getIt<GNFirestore>().listenForMatchesUpdated(leagueId);
  }

  @override
  Stream<GNEsportLeague> listenForLeagueUpdated(String leagueId) {
    return getIt<GNFirestore>().listenForLeagueUpdated(leagueId);
  }

  @override
  Stream<List<GNEsportLeagueStat>> listenForLeagueStats(String leagueId) {
    return getIt<GNFirestore>().listenForLeagueStats(leagueId);
  }

  @override
  Future<List<GNEsportLeague>> getLeaguesByGroupId(String groupId) {
    return getIt<GNFirestore>().getLeaguesByGroupId(groupId);
  }

  @override
  Future<void> replaceParticipant({
    required String leagueId,
    required String oldUserId,
    required String newUserId,
  }) {
    return getIt<GNFirestore>().replaceParticipantInLeague(
      leagueId: leagueId,
      oldUserId: oldUserId,
      newUserId: newUserId,
    );
  }

  @override
  Future<void> setMergeCompleted(String leagueId, {required bool completed}) {
    return getIt<GNFirestore>().setMergeCompleted(leagueId, completed: completed);
  }

}
