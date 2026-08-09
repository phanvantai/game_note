import 'package:equatable/equatable.dart';

import 'gn_esport_match.dart';

/// One fixture produced by [buildRoundRobinSchedule].
///
/// [matchday] is 1-based and **relative to the leg being generated**. The
/// absolute matchday is applied by the caller after it has reserved a range,
/// which keeps this file a pure function of its inputs.
class ScheduledPairing extends Equatable {
  final String homeId;
  final String awayId;
  final int matchday;

  const ScheduledPairing({
    required this.homeId,
    required this.awayId,
    required this.matchday,
  });

  @override
  List<Object?> get props => [homeId, awayId, matchday];

  @override
  String toString() =>
      'ScheduledPairing($homeId vs $awayId, matchday $matchday)';
}

/// Builds one full round-robin leg: every pair of [teamIds] meets exactly
/// once, spread over matchdays so that nobody plays twice in the same
/// matchday.
///
/// Uses the circle method — the first team stays fixed while the rest rotate.
/// An odd team count gets a synthetic bye whose fixtures are dropped, so that
/// leg has one resting team per matchday. `n` teams produce `n - 1` matchdays
/// when `n` is even and `n` matchdays when `n` is odd.
///
/// Home/away is decided per pair from [existingMatches]: within a head-to-head,
/// whoever has been at home fewer times gets home advantage, so a second leg
/// mirrors the first. Ties fall back to the circle-method order. Only matches
/// between the two teams of a pair are counted, so an unrelated fixture never
/// shifts another pair's orientation. Passing a stale [existingMatches] can
/// only make one pair's home/away less balanced — it cannot duplicate or drop
/// a fixture.
///
/// Returns an empty list for fewer than two distinct, non-empty team ids.
List<ScheduledPairing> buildRoundRobinSchedule({
  required List<String> teamIds,
  required List<GNEsportMatch> existingMatches,
}) {
  final teams = _distinctIds(teamIds);
  if (teams.length < 2) return const [];

  final homeCounts = _homeCountsByPair(existingMatches);

  const bye = '';
  var rotation = [...teams, if (teams.length.isOdd) bye];
  final size = rotation.length;
  final schedule = <ScheduledPairing>[];

  for (int round = 0; round < size - 1; round++) {
    for (int i = 0; i < size ~/ 2; i++) {
      var home = rotation[i];
      var away = rotation[size - 1 - i];
      if (home == bye || away == bye) continue;

      // Alternate the fixed team's ground between matchdays so a single leg
      // is roughly balanced before any mirroring kicks in.
      if (i == 0 && round.isOdd) {
        final swap = home;
        home = away;
        away = swap;
      }

      if (_homeCountOf(homeCounts, away, home) <
          _homeCountOf(homeCounts, home, away)) {
        final swap = home;
        home = away;
        away = swap;
      }

      schedule.add(
        ScheduledPairing(homeId: home, awayId: away, matchday: round + 1),
      );
    }

    rotation = [
      rotation.first,
      rotation.last,
      ...rotation.sublist(1, size - 1),
    ];
  }

  return schedule;
}

List<String> _distinctIds(List<String> teamIds) {
  final seen = <String>{};
  final unique = <String>[];
  for (final id in teamIds) {
    if (id.isEmpty || !seen.add(id)) continue;
    unique.add(id);
  }
  return unique;
}

/// `'home|away' -> times home hosted away`.
Map<String, int> _homeCountsByPair(List<GNEsportMatch> matches) {
  final counts = <String, int>{};
  for (final match in matches) {
    final key = '${match.homeTeamId}|${match.awayTeamId}';
    counts[key] = (counts[key] ?? 0) + 1;
  }
  return counts;
}

int _homeCountOf(Map<String, int> counts, String home, String away) {
  return counts['$home|$away'] ?? 0;
}
