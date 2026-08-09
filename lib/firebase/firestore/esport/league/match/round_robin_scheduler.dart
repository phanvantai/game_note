import 'package:equatable/equatable.dart';

import 'gn_esport_match.dart';

/// Largest participant count whose round-robin leg still fits a single
/// Firestore transaction: `n(n - 1) / 2` match writes plus one counter update
/// must stay within Firestore's 500-operation ceiling. 32 players → 496
/// matches; 33 → 528.
const int kMaxRoundRobinParticipants = 32;

/// Thrown when a league has so many participants that one round-robin leg
/// cannot be written in a single Firestore transaction.
///
/// A leg is written atomically on purpose: chunked writes can leave a leg
/// half-created, and no retry path can tell the difference between "finish
/// this leg" and "start another one". Failing early with a clear error beats
/// partial state that nothing repairs.
///
/// Lives here rather than in the Firestore layer so the presentation layer can
/// catch it without importing a Firestore extension.
class RoundTooLargeException implements Exception {
  final int participantCount;
  final int maxParticipants;

  RoundTooLargeException({
    required this.participantCount,
    required this.maxParticipants,
  });

  @override
  String toString() =>
      'RoundTooLargeException: $participantCount participants exceeds the '
      'maximum of $maxParticipants for a single atomically written leg.';
}

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

/// Whether a schedule built before the matchday range was reserved still has
/// the right home/away orientation.
///
/// Orientation comes from a read of the existing matches taken *before* the
/// transaction, because Firestore transactions cannot run collection queries —
/// only `get` on a document. If another client reserved legs in between, that
/// read is one or more legs stale, and the schedule sits on the wrong side of
/// the home/away alternation. Each whole leg missed flips the correct side, so
/// an odd number of missed legs means the built schedule must be flipped.
///
/// [expectedAllocated] is how many matchdays existed when orientation was
/// computed; [actualAllocated] is what the transaction actually found on the
/// league document.
bool shouldFlipForMissedLegs({
  required int expectedAllocated,
  required int actualAllocated,
  required int matchdaysInLeg,
}) {
  if (matchdaysInLeg <= 0) return false;
  final missed = actualAllocated - expectedAllocated;
  if (missed <= 0) return false;
  return (missed ~/ matchdaysInLeg).isOdd;
}

/// Swaps home and away in every pairing, leaving matchdays untouched.
List<ScheduledPairing> flipPairings(List<ScheduledPairing> schedule) {
  return [
    for (final pairing in schedule)
      ScheduledPairing(
        homeId: pairing.awayId,
        awayId: pairing.homeId,
        matchday: pairing.matchday,
      ),
  ];
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
