import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/services/group_overview_year_filter.dart';

GNEsportLeague _league(
  String id, {
  int year = 2025,
  String status = 'finished',
  List<String> participants = const [],
}) =>
    GNEsportLeague(
      id: id,
      ownerId: 'owner1',
      groupId: 'G1',
      name: 'League $id',
      startDate: DateTime(year, 6, 1),
      isActive: status != 'finished',
      description: '',
      participants: participants,
      status: status,
    );

GNEsportLeagueStat _stat(
  String leagueId,
  String userId, {
  int matches = 3,
  int wins = 2,
  int draws = 0,
  int losses = 1,
  int goals = 4,
  int goalsConceded = 2,
}) =>
    GNEsportLeagueStat(
      id: '$leagueId-$userId',
      leagueId: leagueId,
      userId: userId,
      matchesPlayed: matches,
      wins: wins,
      draws: draws,
      losses: losses,
      goals: goals,
      goalsConceded: goalsConceded,
    );

void main() {
  group('GroupOverviewYearFilter.aggregate', () {
    test('không có league trong năm → summary rỗng', () {
      final result = GroupOverviewYearFilter.aggregate(
        leagues: [_league('L1', year: 2024)],
        year: 2025,
        statsByLeague: {},
      );
      expect(result.totalLeagues, 0);
      expect(result.finishedLeagues, 0);
      expect(result.playerStats, isEmpty);
    });

    test('totalLeagues và finishedLeagues đúng theo năm', () {
      final leagues = [
        _league('L1', year: 2025, status: 'finished'),
        _league('L2', year: 2025, status: 'ongoing'),
        _league('L3', year: 2025, status: 'finished'),
        _league('L4', year: 2024, status: 'finished'),
      ];
      final result = GroupOverviewYearFilter.aggregate(
        leagues: leagues,
        year: 2025,
        statsByLeague: const {},
      );
      expect(result.totalLeagues, 3);
      expect(result.finishedLeagues, 2);
    });

    test('stats cộng dồn đúng từ 1 league', () {
      final leagues = [_league('L1', year: 2025)];
      final statsByLeague = {
        'L1': [
          _stat('L1', 'A', matches: 3, wins: 2, draws: 0, losses: 1, goals: 5, goalsConceded: 2),
          _stat('L1', 'B', matches: 3, wins: 1, draws: 1, losses: 1, goals: 3, goalsConceded: 3),
        ],
      };
      final result = GroupOverviewYearFilter.aggregate(
        leagues: leagues,
        year: 2025,
        statsByLeague: statsByLeague,
      );
      final a = result.playerStats.firstWhere((p) => p.userId == 'A');
      expect(a.matches, 3);
      expect(a.wins, 2);
      expect(a.draws, 0);
      expect(a.losses, 1);
      expect(a.goals, 5);
      expect(a.goalsConceded, 2);
    });

    test('stats cộng dồn đúng từ 2 leagues cùng năm', () {
      final leagues = [
        _league('L1', year: 2025),
        _league('L2', year: 2025),
      ];
      final statsByLeague = {
        'L1': [_stat('L1', 'A', matches: 3, wins: 2, goals: 4, goalsConceded: 1)],
        'L2': [_stat('L2', 'A', matches: 4, wins: 3, goals: 6, goalsConceded: 2)],
      };
      final result = GroupOverviewYearFilter.aggregate(
        leagues: leagues,
        year: 2025,
        statsByLeague: statsByLeague,
      );
      final a = result.playerStats.firstWhere((p) => p.userId == 'A');
      expect(a.matches, 7);
      expect(a.wins, 5);
      expect(a.goals, 10);
      expect(a.goalsConceded, 3);
    });

    test('league khác năm không ảnh hưởng', () {
      final leagues = [
        _league('L1', year: 2025),
        _league('L2', year: 2024),
      ];
      final statsByLeague = {
        'L1': [_stat('L1', 'A', matches: 3, wins: 2)],
        'L2': [_stat('L2', 'A', matches: 5, wins: 4)],
      };
      final result = GroupOverviewYearFilter.aggregate(
        leagues: leagues,
        year: 2025,
        statsByLeague: statsByLeague,
      );
      final a = result.playerStats.firstWhere((p) => p.userId == 'A');
      expect(a.matches, 3);
      expect(a.wins, 2);
    });

    test('rank 1 của finished league được tính là champion', () {
      final leagues = [_league('L1', year: 2025, status: 'finished')];
      final statsByLeague = {
        'L1': [
          _stat('L1', 'A', wins: 3, goals: 9, goalsConceded: 0),
          _stat('L1', 'B', wins: 2, goals: 5, goalsConceded: 3),
          _stat('L1', 'C', wins: 0, goals: 1, goalsConceded: 7),
        ],
      };
      final result = GroupOverviewYearFilter.aggregate(
        leagues: leagues,
        year: 2025,
        statsByLeague: statsByLeague,
      );
      final a = result.playerStats.firstWhere((p) => p.userId == 'A');
      final b = result.playerStats.firstWhere((p) => p.userId == 'B');
      final c = result.playerStats.firstWhere((p) => p.userId == 'C');

      expect(a.championships, 1);
      expect(b.championships, 0);
      expect(b.runnerUps, 1);
      expect(c.championships, 0);
      expect(c.runnerUps, 0);
    });

    test('finishedLeaguesJoined chỉ tính ở finished leagues', () {
      final leagues = [
        _league('L1', year: 2025, status: 'finished'),
        _league('L2', year: 2025, status: 'ongoing'),
      ];
      final statsByLeague = {
        'L1': [_stat('L1', 'A')],
        'L2': [_stat('L2', 'A')],
      };
      final result = GroupOverviewYearFilter.aggregate(
        leagues: leagues,
        year: 2025,
        statsByLeague: statsByLeague,
      );
      final a = result.playerStats.firstWhere((p) => p.userId == 'A');
      expect(a.finishedLeaguesJoined, 1);
    });

    test('tie-break goal-diff khi wins bằng nhau', () {
      final leagues = [_league('L1', year: 2025, status: 'finished')];
      final statsByLeague = {
        'L1': [
          _stat('L1', 'A', wins: 2, goals: 8, goalsConceded: 2),
          _stat('L1', 'B', wins: 2, goals: 5, goalsConceded: 5),
        ],
      };
      final result = GroupOverviewYearFilter.aggregate(
        leagues: leagues,
        year: 2025,
        statsByLeague: statsByLeague,
      );
      final a = result.playerStats.firstWhere((p) => p.userId == 'A');
      final b = result.playerStats.firstWhere((p) => p.userId == 'B');

      expect(a.championships, 1);
      expect(b.runnerUps, 1);
    });

    test('championships cộng dồn qua 2 finished leagues', () {
      final leagues = [
        _league('L1', year: 2025, status: 'finished'),
        _league('L2', year: 2025, status: 'finished'),
      ];
      final statsByLeague = {
        'L1': [
          _stat('L1', 'A', wins: 3),
          _stat('L1', 'B', wins: 1),
        ],
        'L2': [
          _stat('L2', 'A', wins: 3),
          _stat('L2', 'B', wins: 1),
        ],
      };
      final result = GroupOverviewYearFilter.aggregate(
        leagues: leagues,
        year: 2025,
        statsByLeague: statsByLeague,
      );
      final a = result.playerStats.firstWhere((p) => p.userId == 'A');
      expect(a.championships, 2);
      expect(a.finishedLeaguesJoined, 2);
    });

    test('league có stats rỗng được bỏ qua', () {
      final leagues = [
        _league('L1', year: 2025, status: 'finished'),
        _league('L2', year: 2025, status: 'finished'),
      ];
      final statsByLeague = {
        'L1': [_stat('L1', 'A', wins: 3)],
        // L2 không có stats
      };
      final result = GroupOverviewYearFilter.aggregate(
        leagues: leagues,
        year: 2025,
        statsByLeague: statsByLeague,
      );
      expect(result.totalLeagues, 2);
      expect(result.finishedLeagues, 2);
      final a = result.playerStats.firstWhere((p) => p.userId == 'A');
      expect(a.championships, 1);
      expect(a.finishedLeaguesJoined, 1);
    });

    test('groupId được lấy từ league đầu tiên trong năm', () {
      final leagues = [_league('L1', year: 2025)];
      final result = GroupOverviewYearFilter.aggregate(
        leagues: leagues,
        year: 2025,
        statsByLeague: const {},
      );
      expect(result.groupId, 'G1');
    });

    test('deactivated: loại league có deactivated user tham gia', () {
      final leagues = [
        _league('L1', year: 2025, participants: ['A', 'B']),
        _league('L2', year: 2025, participants: ['A', 'deactivated']),
        _league('L3', year: 2025, participants: ['A', 'C']),
      ];
      final statsByLeague = {
        'L1': [_stat('L1', 'A', wins: 2), _stat('L1', 'B', wins: 1)],
        'L2': [_stat('L2', 'A', wins: 3), _stat('L2', 'deactivated', wins: 0)],
        'L3': [_stat('L3', 'A', wins: 1), _stat('L3', 'C', wins: 2)],
      };
      final result = GroupOverviewYearFilter.aggregate(
        leagues: leagues,
        year: 2025,
        statsByLeague: statsByLeague,
        deactivatedIds: {'deactivated'},
      );
      // L2 excluded → A gets stats from L1 + L3 only
      final a = result.playerStats.firstWhere((p) => p.userId == 'A');
      expect(a.wins, 3); // 2 + 1
      expect(result.totalLeagues, 2); // L1 + L3 only
      // deactivated user không có trong playerStats
      expect(result.playerStats.any((p) => p.userId == 'deactivated'), isFalse);
    });

    test('deactivated: deactivatedIds rỗng → không lọc gì', () {
      final leagues = [
        _league('L1', year: 2025, participants: ['A', 'B']),
      ];
      final statsByLeague = {
        'L1': [_stat('L1', 'A', wins: 2), _stat('L1', 'B', wins: 1)],
      };
      final result = GroupOverviewYearFilter.aggregate(
        leagues: leagues,
        year: 2025,
        statsByLeague: statsByLeague,
      );
      expect(result.totalLeagues, 1);
      expect(result.playerStats.length, 2);
    });
  });
}
