import 'package:pes_arena/api/api_client.dart';
import 'package:pes_arena/api/api_json.dart';
import 'package:pes_arena/api/league_events_hub.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart'
    show ConcurrentMatchUpdateException;
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

/// [EsportLeagueRepository] backed by the Game Note REST API. Realtime
/// streams share one SSE connection per league through [LeagueEventsHub].
class ApiEsportLeagueRepository implements EsportLeagueRepository {
  ApiEsportLeagueRepository({
    required ApiClient client,
    required LeagueEventsHub events,
  }) : _client = client,
       _events = events;

  final ApiClient _client;
  final LeagueEventsHub _events;

  String _league(String leagueId) => '/v1/leagues/$leagueId';

  List<GNEsportLeague> _leagues(Object? json) =>
      apiMapList(json).map(GNEsportLeague.fromApi).toList();

  Future<LeaguesPage> _page(String scope, Object? startAfter, int limit) async {
    final json =
        await _client.get(
              '/v1/leagues',
              query: {
                'scope': scope,
                'limit': '$limit',
                if (startAfter is String) 'cursor': startAfter,
              },
            )
            as Map<String, dynamic>;
    return LeaguesPage(
      items: _leagues(json['items']),
      lastDoc: json['nextCursor'] as String?,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }

  @override
  Future<LeaguesPage> getMyLeagues({Object? startAfter, int limit = 20}) =>
      _page('mine', startAfter, limit);

  @override
  Future<LeaguesPage> getManagedLeagues({Object? startAfter, int limit = 20}) =>
      _page('managed', startAfter, limit);

  @override
  Future<LeaguesPage> getOtherLeagues({Object? startAfter, int limit = 20}) =>
      _page('others', startAfter, limit);

  @override
  Future<List<GNEsportLeague>> getLeaguesByOwnerId(String ownerId) async =>
      _leagues(await _client.get('/v1/leagues', query: {'ownerId': ownerId}));

  @override
  Future<List<GNEsportLeague>> getActiveLeaguesByGroupIds(
    List<String> groupIds,
  ) async {
    if (groupIds.isEmpty) return [];
    return _leagues(
      await _client.get('/v1/leagues', query: {'groupIds': groupIds.join(',')}),
    );
  }

  @override
  Future<List<GNEsportLeague>> getLeaguesByGroupId(String groupId) async =>
      _leagues(await _client.get('/v1/groups/$groupId/leagues'));

  @override
  Future<GNEsportLeague?> getLeague(String leagueId) async {
    try {
      final json = await _client.get(_league(leagueId));
      return GNEsportLeague.fromApi(json as Map<String, dynamic>);
    } on ApiException catch (e) {
      if (e.isNotFound) return null;
      rethrow;
    }
  }

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
    bool defaultPerGoalEnabled = false,
    int defaultCostPerGoal = 50000,
    TournamentMode mode = TournamentMode.league,
    int groupCount = 1,
    int advanceCount = 2,
    List<String> participants = const [],
    List<String> knockoutSeeding = const [],
  }) async {
    final json =
        await _client.post(
              '/v1/leagues',
              body: {
                'name': name,
                'groupId': groupId,
                if (startDate != null) 'startDate': toApiDate(startDate),
                if (endDate != null) 'endDate': toApiDate(endDate),
                'description': description,
                'rankPayoutEnabled': rankPayoutEnabled,
                'rankPayouts': rankPayouts,
                'defaultMatchCost': defaultMatchCost,
                'defaultPerGoalEnabled': defaultPerGoalEnabled,
                'defaultCostPerGoal': defaultCostPerGoal,
                'mode': mode.value,
                'groupCount': groupCount,
                'advanceCount': advanceCount,
                'participants': participants,
                'knockoutSeeding': knockoutSeeding,
              },
            )
            as Map<String, dynamic>;
    return json['id'] as String;
  }

  @override
  Future<void> updateLeague(GNEsportLeague league) =>
      _client.patch(_league(league.id), body: league.toApiPatch());

  @override
  Future<void> inactiveLeague(GNEsportLeague league) =>
      _client.post('${_league(league.id)}/deactivate');

  @override
  Future<void> deleteLeague(String leagueId) =>
      _client.delete(_league(leagueId));

  @override
  Future<void> transferLeagueOwnership({
    required String leagueId,
    required String newOwnerId,
  }) => _client.post(
    '${_league(leagueId)}/transfer-ownership',
    body: {'newOwnerId': newOwnerId},
  );

  @override
  Future<void> addParticipant({
    required String leagueId,
    required String userId,
  }) => addMultipleParticipants(leagueId: leagueId, userIds: [userId]);

  @override
  Future<void> addMultipleParticipants({
    required String leagueId,
    required List<String> userIds,
  }) => _client.post(
    '${_league(leagueId)}/participants',
    body: {'userIds': userIds},
  );

  @override
  Future<void> replaceParticipant({
    required String leagueId,
    required String oldUserId,
    required String newUserId,
  }) => _client.post(
    '${_league(leagueId)}/replace-participant',
    body: {'oldUserId': oldUserId, 'newUserId': newUserId},
  );

  @override
  Future<void> setMergeCompleted(String leagueId, {required bool completed}) =>
      _client.put(
        '${_league(leagueId)}/merge-completed',
        body: {'completed': completed},
      );

  @override
  Future<void> generateRound({
    required String leagueId,
    required List<String> teamIds,
  }) => _client.post('${_league(leagueId)}/rounds', body: {'teamIds': teamIds});

  @override
  Future<void> generateGroupRound({
    required String leagueId,
    required String groupId,
    required List<String> teamIds,
  }) => _client.post(
    '${_league(leagueId)}/group-rounds',
    body: {'groupId': groupId, 'teamIds': teamIds},
  );

  @override
  Future<void> generateCupBracket({
    required String leagueId,
    required List<String> seededTeamIds,
  }) => _client.post(
    '${_league(leagueId)}/cup-bracket',
    body: {'seededTeamIds': seededTeamIds},
  );

  @override
  Future<void> generateFullTournament({
    required String leagueId,
    required List<List<String>> groups,
    required int advanceCount,
    List<String> knockoutSeeding = const [],
  }) => _client.post(
    '${_league(leagueId)}/full-tournament',
    body: {
      'groups': groups,
      'advanceCount': advanceCount,
      'knockoutSeeding': knockoutSeeding,
    },
  );

  @override
  Future<List<GNEsportMatch>> getMatches(String leagueId) async => apiMapList(
    await _client.get('${_league(leagueId)}/matches'),
  ).map(GNEsportMatch.fromApi).toList();

  @override
  Future<void> createCustomMatch(GNEsportMatch match) => _client.post(
    '${_league(match.leagueId)}/matches',
    body: match.toApiCreate(),
  );

  @override
  Future<void> updateMatchAtomically(GNEsportMatch match) async {
    try {
      await _client.patch(
        '${_league(match.leagueId)}/matches/${match.id}',
        body: {
          if (match.homeScore != null) 'homeScore': match.homeScore,
          if (match.awayScore != null) 'awayScore': match.awayScore,
          if (match.matchCost != null) 'matchCost': match.matchCost,
          if (match.costPerGoal != null) 'costPerGoal': match.costPerGoal,
          'expectedUpdatedAt': toApiDateOrNull(match.updatedAt?.toDate()),
        },
      );
    } on ApiException catch (e) {
      if (e.code == 'concurrent_update') {
        throw ConcurrentMatchUpdateException(match.id);
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteMatch(GNEsportMatch match) =>
      _client.delete('${_league(match.leagueId)}/matches/${match.id}');

  @override
  Future<List<GNEsportLeagueStat>> getLeagueStats(String leagueId) async =>
      apiMapList(
        await _client.get('${_league(leagueId)}/stats'),
      ).map(GNEsportLeagueStat.fromApi).toList();

  @override
  Future<void> recomputeLeagueStats(String leagueId) =>
      _client.post('${_league(leagueId)}/stats/recompute');

  @override
  Future<Map<String, GNUser>> getUsersByIds(List<String> userIds) =>
      fetchUsersByIds(_client, userIds);

  @override
  Stream<GNEsportLeague?> listenForLeagueUpdated(String leagueId) =>
      _events.league(leagueId);

  @override
  Stream<List<GNEsportMatch>> listenForMatchesUpdated(String leagueId) =>
      _events.matches(leagueId);

  @override
  Stream<List<GNEsportLeagueStat>> listenForLeagueStats(String leagueId) =>
      _events.stats(leagueId);
}

/// `POST /v1/users/batch`, shared by the league and user repositories.
Future<Map<String, GNUser>> fetchUsersByIds(
  ApiClient client,
  List<String> userIds,
) async {
  final ids = userIds.where((id) => id.isNotEmpty).toSet().toList();
  if (ids.isEmpty) return {};
  final json =
      await client.post('/v1/users/batch', body: {'ids': ids})
          as Map<String, dynamic>;
  return {
    for (final user in apiMapList(json['users']).map(GNUser.fromApi))
      user.id: user,
  };
}
