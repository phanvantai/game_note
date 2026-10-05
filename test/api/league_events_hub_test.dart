import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pes_arena/api/api_client.dart';
import 'package:pes_arena/api/league_events_hub.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';

import 'fake_api.dart';

/// Scripted SSE backend. Each connection attempt consumes the next behaviour
/// (`open` when the script is exhausted).
class _SseServer {
  final script = <String>[];
  final connections = <StreamController<List<int>>>[];
  final paths = <String>[];
  Completer<void>? gate;

  StreamController<List<int>> get current => connections.last;

  void send(String text) => current.add(utf8.encode(text));

  void snapshot(Map<String, dynamic> json) =>
      send('event: snapshot\ndata: ${jsonEncode(json)}\n\n');

  ApiClient client() => ApiClient(
    httpClient: MockClient.streaming((request, _) async {
      paths.add(request.url.path);
      final behaviour = script.isEmpty ? 'open' : script.removeAt(0);
      final pending = gate;
      if (pending != null) await pending.future;
      switch (behaviour) {
        case 'throw':
          throw http.ClientException('offline');
        case '404':
        case '401':
          return http.StreamedResponse(
            Stream.value(utf8.encode('{"error":"x"}')),
            int.parse(behaviour),
          );
        case '500':
          return http.StreamedResponse(Stream.value(utf8.encode('')), 500);
        default:
          final controller = StreamController<List<int>>();
          connections.add(controller);
          return http.StreamedResponse(controller.stream, 200);
      }
    }),
    tokenProvider: () async => 't',
    baseUrl: 'https://api.test',
  );
}

Map<String, dynamic> _snapshot({String name = 'League l1'}) => {
  'league': {...leagueJson('l1'), 'name': name},
  'matches': [matchJson('m1')],
  'stats': [statJson('s1', 'a')],
};

Future<void> _tick([int ms = 5]) =>
    Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  late _SseServer server;
  late LeagueEventsHub hub;

  setUp(() {
    server = _SseServer();
    hub = LeagueEventsHub(
      server.client(),
      initialBackoff: const Duration(milliseconds: 10),
      maxBackoff: const Duration(milliseconds: 20),
    );
  });

  test('fans one connection out to league, matches and stats', () async {
    final leagues = <GNEsportLeague?>[];
    final matches = <List<GNEsportMatch>>[];
    final stats = <List<GNEsportLeagueStat>>[];
    final subs = [
      hub.league('l1').listen(leagues.add),
      hub.matches('l1').listen(matches.add),
      hub.stats('l1').listen(stats.add),
    ];
    await _tick();

    server.snapshot(_snapshot());
    await _tick();

    expect(server.paths, ['/v1/leagues/l1/events']);
    expect(leagues.single?.name, 'League l1');
    expect(matches.single.single.id, 'm1');
    expect(stats.single.single.userId, 'a');
    expect(hub.hasChannel('l1'), isTrue);

    for (final sub in subs) {
      await sub.cancel();
    }
    expect(hub.hasChannel('l1'), isFalse);
    expect(server.current.hasListener, isFalse);
  });

  test('a late subscriber receives the latest snapshot immediately', () async {
    final first = hub.league('l1').listen((_) {});
    await _tick();
    server.snapshot(_snapshot(name: 'Fresh'));
    await _tick();

    final late = await hub.league('l1').first;

    expect(late?.name, 'Fresh');
    expect(server.paths, hasLength(1));
    await first.cancel();
  });

  test(
    'ignores comments, other events, malformed and non-object frames',
    () async {
      final leagues = <GNEsportLeague?>[];
      final sub = hub.league('l1').listen(leagues.add);
      await _tick();

      server.send(': ping\n\n');
      server.send('event: other\ndata: {}\n\n');
      server.send('event: snapshot\ndata: {not json\n\n');
      server.send('event: snapshot\ndata: [1]\n\n');
      server.send('event: snapshot\n\n');
      server.send('retry\n\n');
      // Multi-line data without the optional space after the colon.
      final json = jsonEncode(_snapshot(name: 'Split'));
      final cut = json.length ~/ 2;
      server.send(
        'event:snapshot\ndata:${json.substring(0, cut)}\n'
        'data:${json.substring(cut)}\n\n',
      );
      await _tick();

      // The joined data contains a newline inside the JSON, which is legal
      // whitespace only between tokens; the frame still parses when the cut
      // lands there, otherwise it is dropped. Either way nothing crashes and
      // a well-formed frame afterwards is delivered.
      server.snapshot(_snapshot(name: 'Last'));
      await _tick();

      expect(leagues.last?.name, 'Last');
      await sub.cancel();
    },
  );

  test('reconnects after the server closes or the network fails', () async {
    server.script.addAll(['open', 'throw', '500', 'open']);
    final leagues = <GNEsportLeague?>[];
    final sub = hub.league('l1').listen(leagues.add);
    await _tick();

    await server.current.close();
    await _tick(80);

    expect(server.paths.length, greaterThanOrEqualTo(4));
    server.snapshot(_snapshot(name: 'Back'));
    await _tick();
    expect(leagues.last?.name, 'Back');

    server.current.addError(Exception('reset'));
    await _tick(40);
    expect(server.paths.length, greaterThanOrEqualTo(5));
    await sub.cancel();
  });

  test(
    'a deleted league (404) emits null and empty lists, then stops',
    () async {
      server.script.add('404');
      final league = hub.league('l1').first;
      final matches = hub.matches('l1').first;

      expect(await league, isNull);
      expect(await matches, isEmpty);
      expect(hub.hasChannel('l1'), isFalse);
      await _tick(30);
      expect(server.paths, hasLength(1));
    },
  );

  test('auth failures (401) surface as stream errors', () async {
    server.script.add('401');

    await expectLater(
      hub.stats('l1').first,
      throwsA(isA<ApiException>().having((e) => e.statusCode, 's', 401)),
    );
    expect(hub.hasChannel('l1'), isFalse);
  });

  test('cancelling during backoff stops reconnecting', () async {
    server.script.add('throw');
    final sub = hub.matches('l1').listen((_) {});
    await _tick(2);

    await sub.cancel();
    await _tick(40);

    expect(server.paths, hasLength(1));
  });

  test('cancelling while connecting closes the late response', () async {
    server.gate = Completer<void>();
    final sub = hub.league('l1').listen((_) {});
    await _tick();

    await sub.cancel();
    server.gate!.complete();
    await _tick();

    expect(server.connections.single.hasListener, isFalse);
    expect(server.paths, hasLength(1));
  });

  test('a channel ended by 404 is replaced for the next subscriber', () async {
    server.script.add('404');
    final ended = hub.league('l1').listen((_) {});
    await _tick();
    expect(hub.hasChannel('l1'), isFalse);

    final fresh = hub.league('l1').listen((_) {});
    await _tick();
    expect(server.paths, hasLength(2));
    expect(hub.hasChannel('l1'), isTrue);

    await ended.cancel();
    expect(hub.hasChannel('l1'), isTrue, reason: 'old channel must not evict');
    await fresh.cancel();
    expect(hub.hasChannel('l1'), isFalse);
  });

  test('LeagueSnapshot.fromApi tolerates a missing league', () {
    final snapshot = LeagueSnapshot.fromApi({'league': null});
    expect(snapshot.league, isNull);
    expect(snapshot.matches, isEmpty);
    expect(snapshot.stats, isEmpty);
  });
}
