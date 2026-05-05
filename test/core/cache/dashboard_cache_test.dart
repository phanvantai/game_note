import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/core/cache/dashboard_cache.dart';
import 'package:pes_arena/presentation/home/dashboard/models/dashboard_stats.dart';
import 'package:pes_arena/presentation/home/dashboard/models/league_performance_point.dart';
import 'package:pes_arena/presentation/home/dashboard/models/opponent_stat.dart';
import 'package:pes_arena/presentation/home/dashboard/models/recent_match_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';

DashboardStats _stats() {
  return DashboardStats(
    tournamentsJoined: 4,
    finishedTournaments: 2,
    championCount: 1,
    runnerUpCount: 1,
    lastChampionAt: DateTime(2026, 1, 10),
    matchesPlayed: 10,
    wins: 6,
    draws: 2,
    losses: 2,
    goals: 18,
    goalsConceded: 9,
    leaguePerformance: [
      LeaguePerformancePoint(
        leagueId: 'l1',
        leagueName: 'Cup',
        lastPlayedAt: DateTime(2026, 4, 1),
        matchesPlayed: 5,
        wins: 3,
        draws: 1,
        losses: 1,
        pointsPerMatch: 2.0,
        goalDifferencePerMatch: 0.6,
      ),
    ],
    opponents: const [
      OpponentStat(
        opponentId: 'u2',
        opponentDisplayName: 'P2',
        matchesPlayed: 4,
        wins: 3,
        draws: 0,
        losses: 1,
      ),
    ],
    recentMatches: [
      RecentMatchSummary(
        matchId: 'm1',
        leagueId: 'l1',
        leagueName: 'Cup',
        date: DateTime(2026, 4, 1),
        userScore: 3,
        opponentScore: 1,
        opponentDisplayName: 'P2',
        result: MatchResult.win,
      ),
      RecentMatchSummary(
        matchId: 'm2',
        leagueId: 'l1',
        leagueName: 'Cup',
        date: DateTime(2026, 3, 20),
        userScore: 0,
        opponentScore: 0,
        opponentDisplayName: 'P3',
        result: MatchResult.draw,
      ),
    ],
  );
}

void main() {
  late DashboardCache cache;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    cache = DashboardCache(prefs);
  });

  test('read trả null khi chưa có cache', () async {
    expect(await cache.read('u1'), isNull);
  });

  test('write rồi read round-trip giữ nguyên giá trị', () async {
    final stats = _stats();
    await cache.write('u1', stats);
    final loaded = await cache.read('u1');
    expect(loaded, isNotNull);
    expect(loaded!.tournamentsJoined, stats.tournamentsJoined);
    expect(loaded.wins, 6);
    expect(loaded.recentMatches.length, 2);
    expect(loaded.recentMatches.first.result, MatchResult.win);
    expect(loaded.lastChampionAt, DateTime(2026, 1, 10));
    expect(loaded.leaguePerformance.length, 1);
    expect(loaded.leaguePerformance.first.leagueName, 'Cup');
    expect(loaded.leaguePerformance.first.pointsPerMatch, 2.0);
    expect(loaded.leaguePerformance.first.goalDifferencePerMatch, 0.6);
    expect(loaded.leaguePerformance.first.lastPlayedAt, DateTime(2026, 4, 1));
    expect(loaded.opponents.length, 1);
    expect(loaded.opponents.first.opponentDisplayName, 'P2');
    expect(loaded.opponents.first.wins, 3);
  });

  test('cache key per-user — user khác không thấy stats', () async {
    await cache.write('u1', _stats());
    expect(await cache.read('u2'), isNull);
  });

  test('clear xoá entry', () async {
    await cache.write('u1', _stats());
    await cache.clear('u1');
    expect(await cache.read('u1'), isNull);
  });

  test('read entry hỏng tự xoá và trả null', () async {
    SharedPreferences.setMockInitialValues({
      'dashboard_cache_v1_u1': '{not valid json',
    });
    final prefs = await SharedPreferences.getInstance();
    final c = DashboardCache(prefs);
    expect(await c.read('u1'), isNull);
    // Subsequent read also null (cache cleared).
    expect(await c.read('u1'), isNull);
  });

  test('read fallback result name lạ → MatchResult.draw', () async {
    SharedPreferences.setMockInitialValues({
      'dashboard_cache_v1_u1':
          '{"tournamentsJoined":0,"finishedTournaments":0,"championCount":0,"runnerUpCount":0,"recentMatches":[{"matchId":"m","leagueId":"l","leagueName":"L","date":0,"userScore":0,"opponentScore":0,"opponentDisplayName":"","result":"unknown"}]}',
    });
    final prefs = await SharedPreferences.getInstance();
    final c = DashboardCache(prefs);
    final loaded = await c.read('u1');
    expect(loaded, isNotNull);
    expect(loaded!.recentMatches.first.result, MatchResult.draw);
  });
}
