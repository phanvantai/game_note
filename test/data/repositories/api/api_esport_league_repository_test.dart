import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/api/api_client.dart';
import 'package:pes_arena/api/league_events_hub.dart';
import 'package:pes_arena/data/repositories/api/api_esport_league_repository.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';

import '../../../api/fake_api.dart';

class _MockHub extends Mock implements LeagueEventsHub {}

GNEsportMatch _match({Timestamp? updatedAt, int? homeScore = 3}) =>
    GNEsportMatch(
      id: 'm1',
      homeTeamId: 'a',
      awayTeamId: 'b',
      homeScore: homeScore,
      awayScore: homeScore == null ? null : 1,
      date: DateTime.utc(2026, 3, 2),
      isFinished: false,
      leagueId: 'l1',
      matchCost: homeScore == null ? null : 20000,
      costPerGoal: homeScore == null ? null : 5000,
      updatedAt: updatedAt,
    );

void main() {
  late FakeApi api;
  late _MockHub hub;
  late ApiEsportLeagueRepository repo;

  setUp(() {
    api = FakeApi();
    hub = _MockHub();
    repo = ApiEsportLeagueRepository(client: api.client(), events: hub);
  });

  group('paginated lists', () {
    final page = {
      'items': [leagueJson('l1', group: groupJson('g1'))],
      'nextCursor': 'c2',
      'hasMore': true,
    };

    test('mine / managed / others pass scope, limit and cursor', () async {
      api.on('GET', '/v1/leagues', page);

      final mine = await repo.getMyLeagues();
      expect(api.last.url.queryParameters, {'scope': 'mine', 'limit': '20'});
      expect(mine.items.single.group?.id, 'g1');
      expect(mine.lastDoc, 'c2');
      expect(mine.hasMore, isTrue);

      await repo.getManagedLeagues(startAfter: 'c2', limit: 5);
      expect(api.last.url.queryParameters, {
        'scope': 'managed',
        'limit': '5',
        'cursor': 'c2',
      });

      await repo.getOtherLeagues(startAfter: Object());
      expect(api.last.url.queryParameters['scope'], 'others');
      expect(api.last.url.queryParameters.containsKey('cursor'), isFalse);
    });

    test('hasMore defaults to false and cursor may be null', () async {
      api.on('GET', '/v1/leagues', {'items': <Object>[], 'nextCursor': null});

      final result = await repo.getMyLeagues();

      expect(result.items, isEmpty);
      expect(result.lastDoc, isNull);
      expect(result.hasMore, isFalse);
    });
  });

  group('filtered lists', () {
    test('by owner, by group ids and by group', () async {
      api.on('GET', '/v1/leagues', [leagueJson('l1')]);
      api.on('GET', '/v1/groups/g1/leagues', [leagueJson('l2')]);

      expect((await repo.getLeaguesByOwnerId('o1')).single.id, 'l1');
      expect(api.last.url.queryParameters, {'ownerId': 'o1'});

      expect(
        (await repo.getActiveLeaguesByGroupIds(['g1', 'g2'])).single.id,
        'l1',
      );
      expect(api.last.url.queryParameters, {'groupIds': 'g1,g2'});

      expect((await repo.getLeaguesByGroupId('g1')).single.id, 'l2');
    });

    test('empty group id list skips the request', () async {
      expect(await repo.getActiveLeaguesByGroupIds([]), isEmpty);
      expect(api.requests, isEmpty);
    });
  });

  group('getLeague', () {
    test('returns the league', () async {
      api.on('GET', '/v1/leagues/l1', leagueJson('l1'));
      expect((await repo.getLeague('l1'))?.id, 'l1');
    });

    test('returns null on 404 and rethrows other errors', () async {
      api.error('GET', '/v1/leagues/gone', 404, 'not_found');
      api.error('GET', '/v1/leagues/secret', 403, 'forbidden');

      expect(await repo.getLeague('gone'), isNull);
      await expectLater(repo.getLeague('secret'), throwsA(isA<ApiException>()));
    });
  });

  test('addLeague posts every field and returns the id', () async {
    api.on('POST', '/v1/leagues', {'id': 'new'});

    final id = await repo.addLeague(
      name: 'S1',
      groupId: 'g1',
      startDate: DateTime.utc(2026, 6),
      endDate: DateTime.utc(2026, 7),
      mode: TournamentMode.full,
      participants: ['a'],
      knockoutSeeding: ['A1'],
    );

    expect(id, 'new');
    expect(api.lastBody, {
      'name': 'S1',
      'groupId': 'g1',
      'startDate': '2026-06-01T00:00:00.000Z',
      'endDate': '2026-07-01T00:00:00.000Z',
      'description': '',
      'rankPayoutEnabled': false,
      'rankPayouts': <int>[],
      'defaultMatchCost': 50000,
      'defaultPerGoalEnabled': false,
      'defaultCostPerGoal': 50000,
      'mode': 'full',
      'groupCount': 1,
      'advanceCount': 2,
      'participants': ['a'],
      'knockoutSeeding': ['A1'],
    });

    await repo.addLeague(name: 'S2', groupId: 'g1');
    expect(api.lastBody.containsKey('startDate'), isFalse);
    expect(api.lastBody.containsKey('endDate'), isFalse);
  });

  test('league mutations hit their endpoints', () async {
    final league = GNEsportLeague.fromApi(leagueJson('l1'));
    final calls = <(String, String, Future<void> Function())>[
      ('PATCH', '/v1/leagues/l1', () => repo.updateLeague(league)),
      ('POST', '/v1/leagues/l1/deactivate', () => repo.inactiveLeague(league)),
      ('DELETE', '/v1/leagues/l1', () => repo.deleteLeague('l1')),
      (
        'POST',
        '/v1/leagues/l1/transfer-ownership',
        () => repo.transferLeagueOwnership(leagueId: 'l1', newOwnerId: 'b'),
      ),
      (
        'POST',
        '/v1/leagues/l1/participants',
        () => repo.addParticipant(leagueId: 'l1', userId: 'c'),
      ),
      (
        'POST',
        '/v1/leagues/l1/replace-participant',
        () => repo.replaceParticipant(
          leagueId: 'l1',
          oldUserId: 'a',
          newUserId: 'z',
        ),
      ),
      (
        'PUT',
        '/v1/leagues/l1/merge-completed',
        () => repo.setMergeCompleted('l1', completed: true),
      ),
      (
        'POST',
        '/v1/leagues/l1/rounds',
        () => repo.generateRound(leagueId: 'l1', teamIds: ['a', 'b']),
      ),
      (
        'POST',
        '/v1/leagues/l1/group-rounds',
        () => repo.generateGroupRound(
          leagueId: 'l1',
          groupId: 'A',
          teamIds: ['a', 'b'],
        ),
      ),
      (
        'POST',
        '/v1/leagues/l1/cup-bracket',
        () =>
            repo.generateCupBracket(leagueId: 'l1', seededTeamIds: ['a', 'b']),
      ),
      (
        'POST',
        '/v1/leagues/l1/full-tournament',
        () => repo.generateFullTournament(
          leagueId: 'l1',
          groups: [
            ['a', 'b'],
          ],
          advanceCount: 2,
        ),
      ),
      ('DELETE', '/v1/leagues/l1/matches/m1', () => repo.deleteMatch(_match())),
      (
        'POST',
        '/v1/leagues/l1/matches',
        () => repo.createCustomMatch(_match()),
      ),
      (
        'POST',
        '/v1/leagues/l1/stats/recompute',
        () => repo.recomputeLeagueStats('l1'),
      ),
    ];
    final expectedBodies = <String, Object?>{
      '/v1/leagues/l1/transfer-ownership': {'newOwnerId': 'b'},
      '/v1/leagues/l1/participants': {
        'userIds': ['c'],
      },
      '/v1/leagues/l1/replace-participant': {
        'oldUserId': 'a',
        'newUserId': 'z',
      },
      '/v1/leagues/l1/merge-completed': {'completed': true},
      '/v1/leagues/l1/rounds': {
        'teamIds': ['a', 'b'],
      },
      '/v1/leagues/l1/group-rounds': {
        'groupId': 'A',
        'teamIds': ['a', 'b'],
      },
      '/v1/leagues/l1/cup-bracket': {
        'seededTeamIds': ['a', 'b'],
      },
      '/v1/leagues/l1/full-tournament': {
        'groups': [
          ['a', 'b'],
        ],
        'advanceCount': 2,
        'knockoutSeeding': <String>[],
      },
    };

    for (final (method, path, call) in calls) {
      api.on(method, path, null, status: 204);
      await call();
      expect(api.last.method, method, reason: path);
      expect(api.last.url.path, path);
      final expected = expectedBodies[path];
      if (expected != null) {
        expect(jsonDecode(api.last.body), expected, reason: path);
      }
    }
    // updateLeague sends the editable fields.
    final patch = api.requests.first;
    expect(jsonDecode(patch.body)['name'], 'League l1');
  });

  group('matches and stats', () {
    test('getMatches / getLeagueStats parse lists', () async {
      api.on('GET', '/v1/leagues/l1/matches', [matchJson('m1')]);
      api.on('GET', '/v1/leagues/l1/stats', [statJson('s1', 'a')]);

      expect((await repo.getMatches('l1')).single.homeTeam?.id, 'a');
      expect((await repo.getLeagueStats('l1')).single.points, 3);
    });

    test('updateMatchAtomically sends scores and the ISO version', () async {
      api.on('PATCH', '/v1/leagues/l1/matches/m1', matchJson('m1'));
      final version = Timestamp.fromDate(DateTime.utc(2026, 3, 2, 10, 0, 0, 5));

      await repo.updateMatchAtomically(_match(updatedAt: version));

      expect(api.lastBody, {
        'homeScore': 3,
        'awayScore': 1,
        'matchCost': 20000,
        'costPerGoal': 5000,
        'expectedUpdatedAt': '2026-03-02T10:00:00.005Z',
      });

      await repo.updateMatchAtomically(_match(homeScore: null));
      expect(api.lastBody, {'expectedUpdatedAt': null});
    });

    test(
      'maps 409 concurrent_update to ConcurrentMatchUpdateException',
      () async {
        api.error(
          'PATCH',
          '/v1/leagues/l1/matches/m1',
          409,
          'concurrent_update',
        );

        await expectLater(
          repo.updateMatchAtomically(_match()),
          throwsA(
            isA<ConcurrentMatchUpdateException>().having(
              (e) => e.matchId,
              'matchId',
              'm1',
            ),
          ),
        );
      },
    );

    test('other match errors propagate as ApiException', () async {
      api.error('PATCH', '/v1/leagues/l1/matches/m1', 409, 'conflict');

      await expectLater(
        repo.updateMatchAtomically(_match()),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'conflict')),
      );
    });
  });

  group('users', () {
    test('getUsersByIds dedupes, drops blanks and keys by id', () async {
      api.on('POST', '/v1/users/batch', {
        'users': [userJson('a'), userJson('b')],
      });

      final users = await repo.getUsersByIds(['a', '', 'b', 'a']);

      expect(api.lastBody, {
        'ids': ['a', 'b'],
      });
      expect(users.keys, ['a', 'b']);
    });

    test('getUsersByIds with nothing to fetch skips the request', () async {
      expect(await repo.getUsersByIds(['', '']), isEmpty);
      expect(api.requests, isEmpty);
    });
  });

  test('listen* delegate to the shared events hub', () {
    final league = StreamController<GNEsportLeague?>().stream;
    final matches = StreamController<List<GNEsportMatch>>().stream;
    final stats = StreamController<List<GNEsportLeagueStat>>().stream;
    when(() => hub.league('l1')).thenAnswer((_) => league);
    when(() => hub.matches('l1')).thenAnswer((_) => matches);
    when(() => hub.stats('l1')).thenAnswer((_) => stats);

    expect(repo.listenForLeagueUpdated('l1'), same(league));
    expect(repo.listenForMatchesUpdated('l1'), same(matches));
    expect(repo.listenForLeagueStats('l1'), same(stats));
  });
}
