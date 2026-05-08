import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_firestore_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

export 'package:pes_arena/firebase/firestore/esport/league/gn_firestore_esport_league.dart'
    show LeaguesPage;

// Data class for parallel loading results
class LeagueDetailData {
  final List<GNEsportLeagueStat> participants;
  final List<GNEsportMatch> matches;

  const LeagueDetailData({
    required this.participants,
    required this.matches,
  });
}

abstract class EsportLeagueRepository {
  /// Leagues the current user participates in as a player. Paginated.
  Future<LeaguesPage> getMyLeagues({Object? startAfter, int limit});

  /// Leagues the current user owns (ownerId == uid). Paginated.
  Future<LeaguesPage> getManagedLeagues({Object? startAfter, int limit});

  /// Leagues the current user is NOT in. Paginated; pass `startAfter` from
  /// the previous page's `lastDoc` to load the next page.
  Future<LeaguesPage> getOtherLeagues({
    Object? startAfter,
    int limit,
  });

  /// Active leagues whose `groupId` is in [groupIds]. Used by the home
  /// banner to surface ongoing tournaments from groups the user has joined.
  Future<List<GNEsportLeague>> getActiveLeaguesByGroupIds(
    List<String> groupIds,
  );

  /// All leagues (including inactive/finished) belonging to [groupId].
  /// Used by the group admin tab to manage participants.
  Future<List<GNEsportLeague>> getLeaguesByGroupId(String groupId);

  /// Atomically replace [oldUserId] with [newUserId] in [leagueId].
  /// If [newUserId] already has stats, they are merged.
  Future<void> replaceParticipant({
    required String leagueId,
    required String oldUserId,
    required String newUserId,
  });

  /// Toggle the mergeCompleted flag on a league.
  Future<void> setMergeCompleted(String leagueId, {required bool completed});

  Future<GNEsportLeague?> getLeague(String leagueId);

  Future<String> addLeague({
    required String name,
    required String groupId,
    DateTime? startDate,
    DateTime? endDate,
    String description = '',
    bool rankPayoutEnabled = false,
    List<int> rankPayouts = const [],
    int defaultMatchCost = 50000,
    TournamentMode mode,
    int groupCount,
    int advanceCount,
    List<String> participants,
    List<String> knockoutSeeding,
  });

  Future<void> generateCupBracket({
    required String leagueId,
    required List<String> seededTeamIds,
  });

  Future<void> generateFullTournament({
    required String leagueId,
    required List<List<String>> groups,
    required int advanceCount,
    List<String> knockoutSeeding,
  });

  Future<List<GNEsportLeagueStat>> getLeagueStats(String leagueId);

  Future<Map<String, GNUser>> getUsersByIds(List<String> userIds);

  Future<void> addParticipant({
    required String leagueId,
    required String userId,
  });

  Future<void> addMultipleParticipants({
    required String leagueId,
    required List<String> userIds,
  });

  Future<void> generateRound({
    required String leagueId,
    required List<String> teamIds,
  });

  Future<void> generateGroupRound({
    required String leagueId,
    required String groupId,
    required List<String> teamIds,
  });

  Future<List<GNEsportMatch>> getMatches(String leagueId);
  Future<void> updateMatch(GNEsportMatch match);
  Future<void> updateLeague(GNEsportLeague league);
  Future<void> inactiveLeague(GNEsportLeague league);
  Future<void> deleteLeague(String leagueId);
  Future<void> deleteMatch(GNEsportMatch match);
  Future<void> createCustomMatch(GNEsportMatch match);

  // Parallel loading method to get both participants and matches efficiently
  Future<LeagueDetailData> getParticipantsAndMatches(String leagueId);

  /// Admin-only: rebuild every stat doc in the league from its finished
  /// matches. Use to recover from drift caused by legacy update bugs or
  /// manual data edits.
  Future<void> recomputeLeagueStats(String leagueId);

  // Streams
  Stream<List<GNEsportLeagueStat>> listenForLeagueStats(String leagueId);
  Stream<List<GNEsportMatch>> listenForMatchesUpdated(String leagueId);
  Stream<GNEsportLeague> listenForLeagueUpdated(String leagueId);
}
