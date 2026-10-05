import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/esport/group/stats/gn_esport_group_stats_summary.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/firebase/firestore/user/stats/gn_user_h2h.dart';
import 'package:pes_arena/firebase/firestore/user/stats/gn_user_stats_summary.dart';

import '../../api/fake_api.dart';

void main() {
  group('fromApi', () {
    test('GNUser reads every field with defaults', () {
      final user = GNUser.fromApi({
        ...userJson('u1', name: 'Tai'),
        'deleted': true,
        'deletedAt': '2026-02-01T00:00:00.000Z',
        'isPlaceholder': true,
        'role': 'admin',
      });
      expect(user.id, 'u1');
      expect(user.displayName, 'Tai');
      expect(user.email, 'u1@test.dev');
      expect(user.isAdmin, isTrue);
      expect(user.isPlaceholder, isTrue);
      expect(user.deletedAt, DateTime.utc(2026, 2));

      final minimal = GNUser.fromApi({'id': 'u2'});
      expect(minimal.role, 'user');
      expect(minimal.deleted, isFalse);
      expect(minimal.isPlaceholder, isFalse);
      expect(minimal.deletedAt, isNull);
    });

    test('GNEsportGroup reads members, dates and defaults', () {
      final group = GNEsportGroup.fromApi({
        ...groupJson('g1', members: ['a', 'b']),
        'deactivatedMembers': ['b'],
      });
      expect(group.members, ['a', 'b']);
      expect(group.deactivatedMembers, ['b']);
      expect(group.createdAt, DateTime.utc(2026));
      expect(group.updatedAt, DateTime.utc(2026, 1, 2));

      final minimal = GNEsportGroup.fromApi({'id': 'g2'});
      expect(minimal.groupName, '');
      expect(minimal.status, 'active');
      expect(minimal.members, isEmpty);
      expect(minimal.createdAt, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('GNEsportLeague embeds its group and parses dates', () {
      final league = GNEsportLeague.fromApi({
        ...leagueJson('l1', group: groupJson('g1')),
        'endDate': '2026-04-01T00:00:00.000Z',
        'mode': 'full',
        'knockoutSeeding': ['A1', 'B1'],
        'rankPayouts': [10000, 5000],
      });
      expect(league.group?.id, 'g1');
      expect(league.startDate, DateTime.utc(2026, 3));
      expect(league.endDate, DateTime.utc(2026, 4));
      expect(league.mode, TournamentMode.full);
      expect(league.knockoutSeeding, ['A1', 'B1']);
      expect(league.rankPayouts, [10000, 5000]);
      expect(league.participants, ['a', 'b']);

      final bare = GNEsportLeague.fromApi({
        'id': 'l2',
        'groupId': 'g1',
        'startDate': '2026-03-01T00:00:00.000Z',
      });
      expect(bare.group, isNull);
      expect(bare.name, '');
      expect(bare.description, '');
    });

    test('GNEsportLeague.toApiPatch carries editable fields only', () {
      final league = GNEsportLeague.fromApi(leagueJson('l1'));
      final patch = league.toApiPatch();
      expect(patch['name'], 'League l1');
      expect(patch['startDate'], '2026-03-01T00:00:00.000Z');
      expect(patch['endDate'], isNull);
      expect(patch['status'], 'ongoing');
      expect(patch['mode'], 'league');
      expect(patch['participants'], ['a', 'b']);
      expect(patch.keys, isNot(contains('id')));
      expect(patch.keys, isNot(contains('ownerId')));
      expect(patch.keys, isNot(contains('groupId')));

      final noStatus = GNEsportLeague(
        id: 'l3',
        ownerId: 'o',
        groupId: 'g',
        name: 'n',
        startDate: DateTime.utc(2026),
        endDate: DateTime.utc(2026, 2),
        isActive: true,
        description: '',
        participants: const [],
      ).toApiPatch();
      expect(noStatus.containsKey('status'), isFalse);
      expect(noStatus['endDate'], '2026-02-01T00:00:00.000Z');
    });

    test('GNEsportMatch keeps updatedAt as a Timestamp version', () {
      final match = GNEsportMatch.fromApi({
        ...matchJson('m1', updatedAt: '2026-03-02T10:00:00.123Z'),
        'awayTeam': userJson('b'),
        'phase': 'knockout',
        'knockoutRound': 0,
        'knockoutSlot': 1,
        'nextMatchId': 'm9',
        'matchCost': 30000,
      });
      expect(
        match.updatedAt,
        Timestamp.fromDate(DateTime.utc(2026, 3, 2, 10, 0, 0, 123)),
      );
      expect(match.date, DateTime.utc(2026, 3, 2, 10));
      expect(match.homeTeam?.id, 'a');
      expect(match.awayTeam?.id, 'b');
      expect(match.phase, 'knockout');
      expect(match.knockoutSlot, 1);
      expect(match.nextMatchId, 'm9');
      expect(match.matchCost, 30000);
      expect(match.matchday, 1);

      final bare = GNEsportMatch.fromApi({
        'id': 'm2',
        'leagueId': 'l1',
        'homeTeamId': '',
        'awayTeamId': '',
        'date': '2026-03-02T10:00:00.000Z',
      });
      expect(bare.updatedAt, isNull);
      expect(bare.isFinished, isFalse);
      expect(bare.homeScore, 0);
      expect(bare.homeTeam, isNull);
    });

    test('GNEsportMatch.toApiCreate serialises the custom match body', () {
      final body = GNEsportMatch(
        id: 'ignored',
        homeTeamId: 'a',
        awayTeamId: 'b',
        homeScore: 1,
        awayScore: 1,
        date: DateTime.utc(2026, 5, 1),
        isFinished: true,
        leagueId: 'l1',
        matchCost: 10000,
        groupId: 'A',
        phase: 'group',
      ).toApiCreate();
      expect(body, {
        'homeTeamId': 'a',
        'awayTeamId': 'b',
        'homeScore': 1,
        'awayScore': 1,
        'date': '2026-05-01T00:00:00.000Z',
        'isFinished': true,
        'matchCost': 10000,
        'costPerGoal': null,
        'phase': 'group',
        'groupId': 'A',
        'knockoutRound': null,
        'knockoutSlot': null,
        'nextMatchId': null,
        'matchday': null,
      });
    });

    test('GNEsportLeagueStat reads totals and the embedded user', () {
      final stat = GNEsportLeagueStat.fromApi({
        ...statJson('s1', 'a'),
        'groupId': 'A',
      });
      expect(stat.points, 3);
      expect(stat.goalDifference, 1);
      expect(stat.groupId, 'A');
      expect(stat.user?.id, 'a');

      final bare = GNEsportLeagueStat.fromApi({
        'id': 's2',
        'userId': 'b',
        'leagueId': 'l1',
      });
      expect(bare.matchesPlayed, 0);
      expect(bare.user, isNull);
    });

    test('GNUserStatsSummary parses ISO dates in nested lists', () {
      final summary = GNUserStatsSummary.fromApi({
        'userId': 'u1',
        'matchesPlayed': 3,
        'wins': 2,
        'lastChampionAt': '2026-01-10T00:00:00.000Z',
        'updatedAt': '2026-05-01T00:00:00.000Z',
        'recentMatches': [
          {
            'matchId': 'm1',
            'leagueId': 'l1',
            'leagueName': 'Cup',
            'date': '2026-04-01T00:00:00.000Z',
            'userScore': 3,
            'opponentScore': 1,
            'opponentId': 'u2',
            'opponentDisplayName': 'Linh',
            'result': 'win',
            'updatedAt': '2026-04-02T00:00:00.000Z',
          },
        ],
        'leagueHistory': [
          {
            'leagueId': 'l1',
            'leagueName': 'Cup',
            'lastPlayedAt': '2026-04-01T00:00:00.000Z',
            'matchesPlayed': 3,
          },
        ],
        'h2hSummary': [
          {'opponentId': 'u2', 'matchesPlayed': 3, 'wins': 2},
        ],
      });
      expect(summary.userId, 'u1');
      expect(summary.lastChampionAt, DateTime.utc(2026, 1, 10));
      expect(summary.recentMatches.single.date, DateTime.utc(2026, 4));
      expect(summary.recentMatches.single.updatedAt, DateTime.utc(2026, 4, 2));
      expect(summary.leagueHistory.single.lastPlayedAt, DateTime.utc(2026, 4));
      expect(summary.h2hSummary.single.wins, 2);
      expect(tsToDate(''), isNull);
      expect(tsToDate('garbage'), isNull);
    });

    test('GNUserH2H reads ids and dates', () {
      final h2h = GNUserH2H.fromApi({
        'userId': 'u1',
        'opponentId': 'u2',
        'opponentDisplayName': 'Linh',
        'matchesPlayed': 4,
        'wins': 1,
        'lastMetAt': '2026-04-01T00:00:00.000Z',
      });
      expect(h2h.userId, 'u1');
      expect(h2h.opponentId, 'u2');
      expect(h2h.lastMetAt, DateTime.utc(2026, 4));
      expect(h2h.winRate, 0.25);
    });

    test('GNEsportGroupStatsSummary reads players and ISO updatedAt', () {
      final summary = GNEsportGroupStatsSummary.fromApi({
        'groupId': 'g1',
        'totalLeagues': 3,
        'finishedLeagues': 2,
        'playerStats': [
          {'userId': 'a', 'displayName': 'A', 'matches': 5, 'championships': 1},
        ],
        'updatedAt': '2026-05-01T00:00:00.000Z',
        'schemaVersion': 1,
      });
      expect(summary.totalLeagues, 3);
      expect(summary.playerStats.single.championships, 1);
      expect(summary.updatedAt, DateTime.utc(2026, 5));

      final empty = GNEsportGroupStatsSummary.fromApi({});
      expect(empty.groupId, '');
      expect(empty.playerStats, isEmpty);
      expect(empty.updatedAt, isNull);
      expect(
        empty.schemaVersion,
        GNEsportGroupStatsSummary.kCurrentSchemaVersion,
      );
    });
  });
}
