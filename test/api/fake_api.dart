import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pes_arena/api/api_client.dart';

/// In-memory stand-in for the backend: routes are keyed by
/// `"METHOD /path"` and every request is recorded for assertions.
class FakeApi {
  final requests = <http.Request>[];
  final _routes = <String, http.Response Function(http.Request)>{};

  void on(String method, String path, Object? json, {int status = 200}) {
    _routes['$method $path'] = (_) => http.Response(
      json == null ? '' : jsonEncode(json),
      status,
      headers: {'content-type': 'application/json'},
    );
  }

  void error(String method, String path, int status, String code) {
    on(method, path, {'error': code, 'message': 'msg $code'}, status: status);
  }

  ApiClient client() => ApiClient(
    httpClient: MockClient((request) async {
      requests.add(request);
      final route = _routes['${request.method} ${request.url.path}'];
      if (route == null) {
        return http.Response('{"error":"no_route"}', 500);
      }
      return route(request);
    }),
    tokenProvider: () async => 'token-1',
    baseUrl: 'https://api.test',
  );

  http.Request get last => requests.last;

  Map<String, dynamic> get lastBody =>
      jsonDecode(last.body) as Map<String, dynamic>;
}

Map<String, dynamic> userJson(String id, {String? name}) => {
  'id': id,
  'displayName': name ?? 'User $id',
  'phoneNumber': null,
  'email': '$id@test.dev',
  'photoUrl': null,
  'role': 'user',
  'isPlaceholder': false,
  'deleted': false,
  'deletedAt': null,
};

Map<String, dynamic> groupJson(String id, {List<String>? members}) => {
  'id': id,
  'groupName': 'Group $id',
  'ownerId': 'owner',
  'members': members ?? ['owner'],
  'deactivatedMembers': <String>[],
  'description': '',
  'status': 'active',
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-01-02T00:00:00.000Z',
};

Map<String, dynamic> leagueJson(String id, {Object? group}) => {
  'id': id,
  'ownerId': 'owner',
  'groupId': 'g1',
  'name': 'League $id',
  'startDate': '2026-03-01T00:00:00.000Z',
  'endDate': null,
  'isActive': true,
  'description': '',
  'participants': ['a', 'b'],
  'status': 'ongoing',
  'rankPayoutEnabled': false,
  'rankPayouts': <int>[],
  'defaultMatchCost': 50000,
  'defaultPerGoalEnabled': false,
  'defaultCostPerGoal': 50000,
  'mergeCompleted': false,
  'mode': 'league',
  'groupCount': 1,
  'advanceCount': 2,
  'knockoutSeeding': <String>[],
  'group': group,
};

Map<String, dynamic> matchJson(String id, {String? updatedAt}) => {
  'id': id,
  'leagueId': 'l1',
  'homeTeamId': 'a',
  'awayTeamId': 'b',
  'homeScore': 2,
  'awayScore': 1,
  'date': '2026-03-02T10:00:00.000Z',
  'isFinished': true,
  'matchCost': null,
  'costPerGoal': null,
  'updatedAt': updatedAt,
  'phase': null,
  'groupId': null,
  'knockoutRound': null,
  'knockoutSlot': null,
  'nextMatchId': null,
  'matchday': 1,
  'homeTeam': userJson('a'),
  'awayTeam': null,
};

Map<String, dynamic> statJson(String id, String userId) => {
  'id': id,
  'userId': userId,
  'leagueId': 'l1',
  'groupId': null,
  'matchesPlayed': 1,
  'goals': 2,
  'goalsConceded': 1,
  'wins': 1,
  'draws': 0,
  'losses': 0,
  'user': userJson(userId),
};
