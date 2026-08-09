import 'package:equatable/equatable.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';

/// One matchday's fixtures, or — when [matchday] is null — the trailing bucket
/// of matches that belong to no matchday: custom one-off matches and leagues
/// created before matchdays existed.
class FixtureSection extends Equatable {
  final int? matchday;
  final List<GNEsportMatch> matches;

  const FixtureSection({required this.matchday, required this.matches});

  bool get isOther => matchday == null;

  @override
  List<Object?> get props => [matchday, matches];
}

/// Groups [matches] into matchday sections, ascending, with unnumbered matches
/// collected into a single trailing section.
///
/// Matchday numbers are rendered as stored — gaps are left alone rather than
/// renumbered, so what the user sees always matches what is in Firestore.
/// Order within a section is preserved from [matches].
List<FixtureSection> groupFixturesByMatchday(List<GNEsportMatch> matches) {
  final byMatchday = <int, List<GNEsportMatch>>{};
  final unnumbered = <GNEsportMatch>[];

  for (final match in matches) {
    final matchday = match.matchday;
    if (matchday == null) {
      unnumbered.add(match);
    } else {
      byMatchday.putIfAbsent(matchday, () => []).add(match);
    }
  }

  final orderedMatchdays = byMatchday.keys.toList()..sort();

  return [
    for (final matchday in orderedMatchdays)
      FixtureSection(matchday: matchday, matches: byMatchday[matchday]!),
    if (unnumbered.isNotEmpty)
      FixtureSection(matchday: null, matches: unnumbered),
  ];
}
