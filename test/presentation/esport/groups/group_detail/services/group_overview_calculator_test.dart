import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/group/stats/gn_esport_group_stats_summary.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/services/group_overview_calculator.dart';

GNEsportGroupPlayerEntry _entry(
  String id, {
  String? name,
  int matches = 0,
  int wins = 0,
  int draws = 0,
  int losses = 0,
  int goals = 0,
  int conceded = 0,
  int championships = 0,
  int runnerUps = 0,
  int finishedJoined = 0,
}) =>
    GNEsportGroupPlayerEntry(
      userId: id,
      displayName: name ?? id,
      photoUrl: null,
      matches: matches,
      wins: wins,
      draws: draws,
      losses: losses,
      goals: goals,
      goalsConceded: conceded,
      championships: championships,
      runnerUps: runnerUps,
      finishedLeaguesJoined: finishedJoined,
    );

GNEsportGroupStatsSummary _summary({
  int totalLeagues = 0,
  int finishedLeagues = 0,
  List<GNEsportGroupPlayerEntry> players = const [],
}) =>
    GNEsportGroupStatsSummary(
      groupId: 'G1',
      totalLeagues: totalLeagues,
      finishedLeagues: finishedLeagues,
      playerStats: players,
      updatedAt: null,
      schemaVersion: GNEsportGroupStatsSummary.kCurrentSchemaVersion,
    );

void main() {
  group('GroupOverviewCalculator.compute', () {
    test('trả về empty overview khi summary rỗng', () {
      final result =
          GroupOverviewCalculator.compute(summary: _summary());
      expect(result.totalLeagues, 0);
      expect(result.champion, isNull);
      expect(result.playerStats, isEmpty);
      expect(result.hasAnyAward, isFalse);
    });

    test('không trao award rate khi dưới ngưỡng (1 finished league)', () {
      final result = GroupOverviewCalculator.compute(
        summary: _summary(
          totalLeagues: 1,
          finishedLeagues: 1,
          players: [
            _entry('a',
                matches: 3, wins: 3, goals: 9,
                championships: 1, finishedJoined: 1),
            _entry('b',
                matches: 3, losses: 3, conceded: 9,
                runnerUps: 1, finishedJoined: 1),
          ],
        ),
      );
      expect(result.champion, isNull);
      expect(result.runnerUpKing, isNull);
      expect(result.playerStats.length, 2);
      expect(result.playerStats.first.player.id, 'a');
    });

    test('champion award rate = championships / finishedLeaguesJoined', () {
      final result = GroupOverviewCalculator.compute(
        summary: _summary(
          totalLeagues: 6,
          finishedLeagues: 6,
          players: [
            _entry('a',
                matches: 30, wins: 25, goals: 60,
                championships: 5, runnerUps: 1, finishedJoined: 6),
            _entry('b',
                matches: 30, wins: 5, losses: 25, goals: 20,
                championships: 1, runnerUps: 5, finishedJoined: 6),
          ],
        ),
      );
      expect(result.champion, isNotNull);
      expect(result.champion!.player.id, 'a');
      expect(result.champion!.numerator, 5);
      expect(result.champion!.sampleSize, 6);
      expect(result.champion!.value, closeTo(5 / 6, 1e-9));
      expect(result.runnerUpKing, isNotNull);
      expect(result.runnerUpKing!.player.id, 'b');
    });

    test('hoà vương theo count tuyệt đối, không bị threshold', () {
      final result = GroupOverviewCalculator.compute(
        summary: _summary(
          totalLeagues: 1,
          finishedLeagues: 0,
          players: [
            _entry('a', matches: 4, draws: 4),
            _entry('b', matches: 1, draws: 1),
          ],
        ),
      );
      expect(result.drawKing, isNotNull);
      expect(result.drawKing!.player.id, 'a');
      expect(result.drawKing!.numerator, 4);
    });

    test('cao thủ và hàng thủ thép áp threshold matches=5', () {
      final result = GroupOverviewCalculator.compute(
        summary: _summary(
          totalLeagues: 1,
          players: [
            // A: 6 trận, win 5 → 83%, 1 conceded/trận
            _entry('a',
                matches: 6, wins: 5, losses: 1, goals: 12, conceded: 6),
            // B: 4 trận → dưới threshold, không tính
            _entry('b',
                matches: 4, wins: 4, goals: 8, conceded: 0),
          ],
        ),
      );
      expect(result.master, isNotNull);
      expect(result.master!.player.id, 'a');
      expect(result.ironDefense, isNotNull);
      expect(result.ironDefense!.player.id, 'a');
    });

    test('tie-break: cùng championship rate → matches nhiều hơn thắng', () {
      final result = GroupOverviewCalculator.compute(
        summary: _summary(
          totalLeagues: 6,
          finishedLeagues: 6,
          players: [
            _entry('a',
                matches: 30, wins: 15, championships: 3, finishedJoined: 6),
            _entry('b',
                matches: 18, wins: 9, championships: 3, finishedJoined: 6),
          ],
        ),
      );
      expect(result.champion, isNotNull);
      expect(result.champion!.player.id, 'a');
    });

    test('totalMatchesPlayed = sum(player matches) / 2', () {
      final result = GroupOverviewCalculator.compute(
        summary: _summary(
          totalLeagues: 1,
          players: [
            _entry('a',
                matches: 3, wins: 2, draws: 1, goals: 4, conceded: 1),
            _entry('b',
                matches: 3, draws: 1, losses: 2, goals: 1, conceded: 4),
          ],
        ),
      );
      expect(result.totalMatchesPlayed, 3);
      expect(result.totalGoals, 5);
    });

    test('placeholder displayName khi server chưa fill tên', () {
      final result = GroupOverviewCalculator.compute(
        summary: _summary(
          totalLeagues: 1,
          players: [
            _entry('ghost', name: '', matches: 5, wins: 5, goals: 10),
          ],
        ),
      );
      expect(result.master, isNotNull);
      expect(result.master!.player.id, 'ghost');
      expect(result.master!.player.isPlaceholder, isTrue);
    });
  });
}
