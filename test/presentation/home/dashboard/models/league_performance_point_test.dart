import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/presentation/home/dashboard/models/league_performance_point.dart';

LeaguePerformancePoint _make({String id = 'l1'}) => LeaguePerformancePoint(
  leagueId: id,
  leagueName: 'Cup',
  lastPlayedAt: DateTime(2026, 1, 1),
  matchesPlayed: 5,
  wins: 3,
  draws: 1,
  losses: 1,
  pointsPerMatch: 2.0,
  goalDifferencePerMatch: 0.6,
);

void main() {
  test('Equatable props phân biệt theo leagueId', () {
    final a = _make();
    final b = _make();
    final c = _make(id: 'l2');
    expect(a, equals(b));
    expect(a == c, isFalse);
    expect(a.props.length, 9);
  });
}
