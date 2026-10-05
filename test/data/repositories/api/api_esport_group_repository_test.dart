import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/api/api_client.dart';
import 'package:pes_arena/data/repositories/api/api_esport_group_repository.dart';
import 'package:pes_arena/data/repositories/api/api_stats_repositories.dart';

import '../../../api/fake_api.dart';

void main() {
  late FakeApi api;

  setUp(() => api = FakeApi());

  group('ApiEsportGroupRepository', () {
    late ApiEsportGroupRepository repo;

    setUp(() => repo = ApiEsportGroupRepository(client: api.client()));

    test('lists groups, optionally by owner', () async {
      api.on('GET', '/v1/groups', [groupJson('g1')]);

      expect((await repo.getEsportGroups()).single.id, 'g1');
      expect(api.last.url.queryParameters, isEmpty);

      expect((await repo.getGroupsByOwnerId('o1')).single.id, 'g1');
      expect(api.last.url.queryParameters, {'ownerId': 'o1'});
    });

    test('createEsportGroup posts name and description', () async {
      api.on('POST', '/v1/groups', groupJson('g9'));

      final group = await repo.createEsportGroup(groupName: 'FC');

      expect(group.id, 'g9');
      expect(api.lastBody, {'groupName': 'FC', 'description': ''});
    });

    test('getGroup returns null on 404 and rethrows other errors', () async {
      api.on('GET', '/v1/groups/g1', groupJson('g1'));
      api.error('GET', '/v1/groups/gone', 404, 'not_found');
      api.error('GET', '/v1/groups/bad', 500, 'internal');

      expect((await repo.getGroup('g1'))?.id, 'g1');
      expect(await repo.getGroup('gone'), isNull);
      await expectLater(repo.getGroup('bad'), throwsA(isA<ApiException>()));
    });

    test('getMembersOfGroup parses users', () async {
      api.on('GET', '/v1/groups/g1/members', [userJson('a'), userJson('b')]);

      final members = await repo.getMembersOfGroup('g1');

      expect(members.map((u) => u.id), ['a', 'b']);
    });

    test('membership and ownership mutations hit their endpoints', () async {
      final calls = <(String, String, Object?, Future<void> Function())>[
        (
          'POST',
          '/v1/groups/g1/members',
          {'userId': 'u2'},
          () => repo.addMemberToGroup(groupId: 'g1', memberId: 'u2'),
        ),
        (
          'DELETE',
          '/v1/groups/g1/members/u2',
          null,
          () => repo.removeMemberFromGroup(groupId: 'g1', memberId: 'u2'),
        ),
        (
          'PUT',
          '/v1/groups/g1/members/u2/deactivation',
          {'deactivated': true},
          () => repo.toggleMemberDeactivation(
            groupId: 'g1',
            userId: 'u2',
            deactivate: true,
          ),
        ),
        (
          'POST',
          '/v1/groups/g1/transfer-ownership',
          {'newOwnerId': 'u2'},
          () => repo.transferGroupOwnership(groupId: 'g1', newOwnerId: 'u2'),
        ),
        (
          'POST',
          '/v1/groups/g1/deactivate',
          null,
          () => repo.deactivateGroup('g1'),
        ),
        ('DELETE', '/v1/groups/g1', null, () => repo.requestDeleteGroup('g1')),
      ];

      for (final (method, path, body, call) in calls) {
        api.on(method, path, null, status: 204);
        await call();
        expect(api.last.method, method, reason: path);
        expect(api.last.url.path, path);
        if (body != null) expect(jsonDecode(api.last.body), body);
      }
    });
  });

  group('stats repositories', () {
    test('user summary and h2h', () async {
      final repo = ApiUserStatsRepository(client: api.client());
      api.on('GET', '/v1/users/u1/summary', {'userId': 'u1', 'wins': 4});
      api.on('GET', '/v1/users/u1/h2h/u2', {
        'userId': 'u1',
        'opponentId': 'u2',
        'matchesPlayed': 2,
      });
      api.error('GET', '/v1/users/u1/h2h/u3', 404, 'not_found');
      api.error('GET', '/v1/users/u1/h2h/u4', 403, 'forbidden');

      expect((await repo.getSummary('u1'))?.wins, 4);
      expect(
        (await repo.getH2H(uid: 'u1', opponentUid: 'u2'))?.matchesPlayed,
        2,
      );
      expect(await repo.getH2H(uid: 'u1', opponentUid: 'u3'), isNull);
      await expectLater(
        repo.getH2H(uid: 'u1', opponentUid: 'u4'),
        throwsA(isA<ApiException>()),
      );
    });

    test('group summary', () async {
      final repo = ApiEsportGroupStatsRepository(client: api.client());
      api.on('GET', '/v1/groups/g1/summary', {
        'groupId': 'g1',
        'totalLeagues': 6,
      });

      expect((await repo.getSummary('g1'))?.totalLeagues, 6);
    });
  });
}
