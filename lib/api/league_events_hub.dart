import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';

import 'api_client.dart';
import 'api_json.dart';

/// One `event: snapshot` frame from `GET /v1/leagues/:id/events`.
class LeagueSnapshot {
  final GNEsportLeague? league;
  final List<GNEsportMatch> matches;
  final List<GNEsportLeagueStat> stats;

  const LeagueSnapshot({
    required this.league,
    required this.matches,
    required this.stats,
  });

  /// What subscribers see once the league no longer exists.
  static const deleted = LeagueSnapshot(league: null, matches: [], stats: []);

  factory LeagueSnapshot.fromApi(Map<String, dynamic> json) {
    final league = json['league'];
    return LeagueSnapshot(
      league: league is Map
          ? GNEsportLeague.fromApi(Map<String, dynamic>.from(league))
          : null,
      matches: apiMapList(json['matches']).map(GNEsportMatch.fromApi).toList(),
      stats: apiMapList(json['stats']).map(GNEsportLeagueStat.fromApi).toList(),
    );
  }
}

/// Shares one Server-Sent Events connection per league between the league,
/// matches and stats streams of an open tournament.
///
/// The connection opens with the first listener and closes when the last one
/// cancels. New listeners immediately receive the latest snapshot, matching
/// Firestore's "current value first" behaviour. Network failures reconnect
/// silently with capped exponential backoff; a deleted league (404) emits a
/// `null` league, and auth failures (401/403) are surfaced as stream errors.
class LeagueEventsHub {
  LeagueEventsHub(
    this._client, {
    this.initialBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(seconds: 30),
  });

  final ApiClient _client;
  final Duration initialBackoff;
  final Duration maxBackoff;
  final Map<String, _LeagueChannel> _channels = {};

  Stream<GNEsportLeague?> league(String leagueId) =>
      _watch(leagueId, (s) => s.league);

  Stream<List<GNEsportMatch>> matches(String leagueId) =>
      _watch(leagueId, (s) => s.matches);

  Stream<List<GNEsportLeagueStat>> stats(String leagueId) =>
      _watch(leagueId, (s) => s.stats);

  @visibleForTesting
  bool hasChannel(String leagueId) => _channels.containsKey(leagueId);

  Stream<T> _watch<T>(String leagueId, T Function(LeagueSnapshot) select) {
    late final StreamController<T> controller;
    _LeagueChannel? channel;
    StreamSubscription<LeagueSnapshot>? subscription;
    controller = StreamController<T>(
      onListen: () {
        final ch = channel = _channels.putIfAbsent(
          leagueId,
          () => _LeagueChannel(leagueId, this)..start(),
        );
        ch.listeners++;
        subscription = ch.snapshots.stream.listen(
          (snapshot) => controller.add(select(snapshot)),
          onError: controller.addError,
        );
        final latest = ch.latest;
        if (latest != null) controller.add(select(latest));
      },
      onCancel: () async {
        await subscription?.cancel();
        final ch = channel!;
        ch.listeners--;
        if (ch.listeners == 0) {
          if (identical(_channels[leagueId], ch)) _channels.remove(leagueId);
          await ch.close();
        }
      },
    );
    return controller.stream;
  }

  void _forget(_LeagueChannel channel) {
    if (identical(_channels[channel.leagueId], channel)) {
      _channels.remove(channel.leagueId);
    }
  }
}

class _LeagueChannel {
  _LeagueChannel(this.leagueId, this._hub);

  final String leagueId;
  final LeagueEventsHub _hub;
  final snapshots = StreamController<LeagueSnapshot>.broadcast();
  LeagueSnapshot? latest;
  int listeners = 0;

  bool _closed = false;
  StreamSubscription<String>? _lines;
  Completer<void>? _connectionDone;
  Completer<void>? _sleeping;
  Timer? _retryTimer;

  void start() => unawaited(_run());

  Future<void> _run() async {
    var backoff = _hub.initialBackoff;
    while (!_closed) {
      try {
        final response = await _hub._client.openEventStream(
          '/v1/leagues/$leagueId/events',
        );
        if (_closed) {
          await response.stream.listen(null).cancel();
          return;
        }
        backoff = _hub.initialBackoff;
        await _consume(response.stream);
      } on ApiException catch (e) {
        if (e.statusCode == 404) {
          _emit(LeagueSnapshot.deleted);
          _terminate();
          return;
        }
        if (e.statusCode == 401 || e.statusCode == 403) {
          if (!_closed) snapshots.addError(e);
          _terminate();
          return;
        }
      } catch (_) {
        // Network failure — fall through to the backoff below.
      }
      if (_closed) return;
      await _sleep(backoff);
      final doubled = backoff * 2;
      backoff = doubled > _hub.maxBackoff ? _hub.maxBackoff : doubled;
    }
  }

  Future<void> _consume(Stream<List<int>> bytes) {
    final done = _connectionDone = Completer<void>();
    void finish() {
      if (!done.isCompleted) done.complete();
    }

    String? event;
    final data = StringBuffer();
    _lines = bytes
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (line.isEmpty) {
              if (event == 'snapshot' && data.isNotEmpty) {
                _dispatch(data.toString());
              }
              event = null;
              data.clear();
              return;
            }
            if (line.startsWith(':')) return; // comment / keep-alive ping
            final colon = line.indexOf(':');
            final field = colon == -1 ? line : line.substring(0, colon);
            var value = colon == -1 ? '' : line.substring(colon + 1);
            if (value.startsWith(' ')) value = value.substring(1);
            if (field == 'event') {
              event = value;
            } else if (field == 'data') {
              if (data.isNotEmpty) data.write('\n');
              data.write(value);
            }
          },
          onError: (Object _) => finish(),
          onDone: finish,
          cancelOnError: true,
        );
    return done.future;
  }

  void _dispatch(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return;
      _emit(LeagueSnapshot.fromApi(Map<String, dynamic>.from(decoded)));
    } catch (e) {
      // A malformed frame must not kill the stream; the next one heals it.
      debugPrint('[LeagueEventsHub] dropped malformed snapshot: $e');
    }
  }

  void _emit(LeagueSnapshot snapshot) {
    if (_closed) return;
    latest = snapshot;
    snapshots.add(snapshot);
  }

  Future<void> _sleep(Duration duration) {
    final sleeping = _sleeping = Completer<void>();
    _retryTimer = Timer(duration, () {
      if (!sleeping.isCompleted) sleeping.complete();
    });
    return sleeping.future;
  }

  /// Stops reconnecting after a terminal response; listeners keep their
  /// subscriptions until they cancel, and the next subscriber starts fresh.
  void _terminate() {
    _closed = true;
    _hub._forget(this);
  }

  Future<void> close() async {
    _closed = true;
    _retryTimer?.cancel();
    final sleeping = _sleeping;
    if (sleeping != null && !sleeping.isCompleted) sleeping.complete();
    await _lines?.cancel();
    final done = _connectionDone;
    if (done != null && !done.isCompleted) done.complete();
    await snapshots.close();
  }
}
