// Parses real backend responses (test/fixtures/api, generated and shape-checked
// by server/test/contract.test.ts) through the API repositories, so a
// contract drift on either side fails a test.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pes_arena/api/api_client.dart';
import 'package:pes_arena/api/league_events_hub.dart';
import 'package:pes_arena/data/repositories/api/api_esport_group_repository.dart';
import 'package:pes_arena/data/repositories/api/api_esport_league_repository.dart';
import 'package:pes_arena/data/repositories/api/api_stats_repositories.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/user/stats/gn_user_stats_summary.dart';

String fixture(String name) =>
    File('test/fixtures/api/$name.json').readAsStringSync();

void main() {
  late ApiClient client;

  setUp(() {
    client = ApiClient(
      tokenProvider: () async => 'token',
      baseUrl: 'https://api.test',
      httpClient: MockClient((request) async {
        final path = request.url.path;
        final name = switch (path) {
          _ when path.endsWith('/summary') && path.startsWith('/v1/users') =>
            'user_summary',
          _ when path.endsWith('/summary') => 'group_summary',
          _ when path.contains('/h2h/') => 'h2h',
          _ when path.endsWith('/matches') => 'matches',
          _ when path.endsWith('/stats') => 'stats',
          '/v1/leagues' => 'leagues_page',
          _ when path.startsWith('/v1/leagues/') => 'league',
          _ when path.startsWith('/v1/groups/') => 'group',
          _ => 'error',
        };
        return http.Response(
          fixture(name),
          name == 'error' ? 404 : 200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
  });

  test('league, page, matches and standings parse', () async {
    final repo = ApiEsportLeagueRepository(
      client: client,
      events: LeagueEventsHub(client),
    );

    final league = (await repo.getLeague('l'))!;
    expect(league.name, 'Autumn Cup');
    expect(league.mode, TournamentMode.full);
    expect(league.status, 'finished');
    expect(league.rankPayouts, [50000]);
    expect(league.endDate, DateTime.utc(2026, 9, 30));
    expect(league.group?.groupName, 'Friends');

    final page = await repo.getMyLeagues();
    expect(page.items.single.id, league.id);
    expect(page.hasMore, isFalse);

    final matches = await repo.getMatches('l');
    final played = matches.firstWhere((m) => m.isFinished);
    expect(played.homeScore, 2);
    expect(played.phase, 'group');
    expect(played.groupId, 'A');
    expect(played.updatedAt, isNotNull);
    expect(played.homeTeam?.displayName, 'Owner');
    final knockout = matches.where((m) => m.phase == 'knockout').toList();
    expect(knockout, isNotEmpty);
    expect(knockout.first.knockoutRound, 0);

    final stats = await repo.getLeagueStats('l');
    final owner = stats.firstWhere((s) => s.userId == 'owner');
    expect(owner.wins, 1);
    expect(owner.groupId, 'A');
    expect(owner.user?.displayName, 'Owner');
  });

  test('group and summaries parse', () async {
    final group = (await ApiEsportGroupRepository(
      client: client,
    ).getGroup('g'))!;
    expect(group.members, ['owner', 'alice', 'bob', 'carol']);

    final userStats = ApiUserStatsRepository(client: client);
    final summary = (await userStats.getSummary('owner'))!;
    expect(summary.wins, 1);
    expect(summary.championCount, 1);
    expect(summary.recentMatches.single.result, GNRecentMatchResult.win);
    expect(summary.recentMatches.single.opponentDisplayName, 'Alice');
    expect(summary.leagueHistory.single.leagueName, 'Autumn Cup');
    expect(summary.h2hSummary.single.opponentId, 'alice');

    final h2h = (await userStats.getH2H(uid: 'owner', opponentUid: 'alice'))!;
    expect(h2h.goals, 2);
    expect(h2h.lastMetAt, isNotNull);

    final groupSummary = (await ApiEsportGroupStatsRepository(
      client: client,
    ).getSummary('g'))!;
    expect(groupSummary.finishedLeagues, 1);
    expect(
      groupSummary.playerStats
          .firstWhere((p) => p.userId == 'owner')
          .championships,
      1,
    );
  });

  test('error body maps to ApiException', () async {
    await expectLater(
      client.get('/v1/users/nobody'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.code, 'code', 'not_found')
            .having((e) => e.isNotFound, 'isNotFound', isTrue),
      ),
    );
  });

  test('SSE snapshot frame parses', () {
    final snapshot = LeagueSnapshot.fromApi({
      'league': jsonDecode(fixture('league')),
      'matches': jsonDecode(fixture('matches')),
      'stats': jsonDecode(fixture('stats')),
    });
    expect(snapshot.league?.name, 'Autumn Cup');
    expect(snapshot.matches, isNotEmpty);
    expect(snapshot.stats, isNotEmpty);
  });
}
