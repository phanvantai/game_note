import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/tournament/cost/cost_summary_panel.dart';

GNEsportLeague _league({
  bool rankPayoutEnabled = false,
  List<int> rankPayouts = const [],
  String? status,
}) {
  return GNEsportLeague(
    id: 'L1',
    ownerId: 'owner',
    groupId: 'G1',
    name: 'Test',
    startDate: DateTime(2026, 1, 1),
    isActive: true,
    description: '',
    participants: const [],
    status: status,
    rankPayoutEnabled: rankPayoutEnabled,
    rankPayouts: rankPayouts,
  );
}

GNUser _user(String id, String name) => GNUser(
      id: id,
      displayName: name,
      phoneNumber: null,
      email: null,
      photoUrl: null,
      role: 'user',
      fcmToken: '',
    );

GNEsportLeagueStat _stat(
  String userId,
  String name, {
  int wins = 0,
  int draws = 0,
  int losses = 0,
  int goals = 0,
  int goalsConceded = 0,
}) {
  return GNEsportLeagueStat(
    id: 'S_$userId',
    userId: userId,
    leagueId: 'L1',
    matchesPlayed: wins + draws + losses,
    goals: goals,
    goalsConceded: goalsConceded,
    wins: wins,
    draws: draws,
    losses: losses,
    user: _user(userId, name),
  );
}

GNEsportMatch _match({
  required String home,
  required String away,
  int? homeScore,
  int? awayScore,
  bool isFinished = true,
  int? matchCost,
  int? knockoutRound,
  GNUser? homeTeam,
  GNUser? awayTeam,
}) {
  return GNEsportMatch(
    id: '$home-$away-${knockoutRound ?? ''}',
    homeTeamId: home,
    awayTeamId: away,
    homeScore: homeScore,
    awayScore: awayScore,
    date: DateTime(2026, 1, 1),
    isFinished: isFinished,
    leagueId: 'L1',
    matchCost: matchCost,
    knockoutRound: knockoutRound,
    phase: knockoutRound != null ? 'knockout' : null,
    homeTeam: homeTeam,
    awayTeam: awayTeam,
  );
}

Widget _wrap(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: child),
    ),
  );
}

void main() {
  testWidgets(
    'render SizedBox rỗng khi không có rank payout và không có match cost',
    (tester) async {
      await tester.pumpWidget(_wrap(CostSummaryPanel(
        league: _league(),
        sortedStats: [_stat('A', 'Alice')],
        matches: const [],
      )));

      expect(find.text('Chi phí'), findsNothing);
    },
  );

  testWidgets(
    'render rank section khi rankPayoutEnabled = true',
    (tester) async {
      await tester.pumpWidget(_wrap(CostSummaryPanel(
        league: _league(
          rankPayoutEnabled: true,
          rankPayouts: const [50000, 100000],
          status: 'ongoing',
        ),
        sortedStats: [
          _stat('A', 'Alice', wins: 2),
          _stat('B', 'Bob', wins: 1),
          _stat('C', 'Charlie'),
        ],
        matches: const [],
      )));

      expect(find.text('Chi phí'), findsOneWidget);
      // 2 transfer (B → A: 50k, C → A: 100k)
      expect(find.text('50k'), findsOneWidget);
      expect(find.text('100k'), findsOneWidget);
      // Net section
      expect(find.text('Tổng ròng'), findsOneWidget);
      // Alice nhận tổng 150k
      expect(find.text('+150k'), findsOneWidget);
    },
  );

  testWidgets(
    'render match cost section khi có match có cost > 0',
    (tester) async {
      await tester.pumpWidget(_wrap(CostSummaryPanel(
        league: _league(),
        sortedStats: [_stat('A', 'Alice'), _stat('B', 'Bob')],
        matches: [
          _match(home: 'A', away: 'B', homeScore: 2, awayScore: 0,
              matchCost: 50000),
        ],
      )));

      expect(find.text('Chi phí'), findsOneWidget);
      expect(find.text('50k'), findsOneWidget);
      expect(find.text('+50k'), findsOneWidget);
      expect(find.text('-50k'), findsOneWidget);
    },
  );

  testWidgets(
    'hiện "(tạm tính)" khi giải chưa kết thúc',
    (tester) async {
      await tester.pumpWidget(_wrap(CostSummaryPanel(
        league: _league(
          rankPayoutEnabled: true,
          rankPayouts: const [50000],
          status: 'ongoing',
        ),
        sortedStats: [_stat('A', 'Alice', wins: 1), _stat('B', 'Bob')],
        matches: const [],
      )));

      expect(find.text('(tạm tính)'), findsOneWidget);
    },
  );

  testWidgets(
    'ẩn "(tạm tính)" khi giải đã finished',
    (tester) async {
      await tester.pumpWidget(_wrap(CostSummaryPanel(
        league: _league(
          rankPayoutEnabled: true,
          rankPayouts: const [50000],
          status: GNEsportLeagueStatus.finished.value,
        ),
        sortedStats: [_stat('A', 'Alice', wins: 1), _stat('B', 'Bob')],
        matches: const [],
      )));

      expect(find.text('(tạm tính)'), findsNothing);
      expect(find.text('Chi phí'), findsOneWidget);
    },
  );

  testWidgets(
    'hiện "Chưa có khoản nào" khi rank payout bật nhưng < 2 người',
    (tester) async {
      await tester.pumpWidget(_wrap(CostSummaryPanel(
        league: _league(
          rankPayoutEnabled: true,
          rankPayouts: const [50000],
          status: 'ongoing',
        ),
        sortedStats: [_stat('A', 'Alice')],
        matches: const [],
      )));

      expect(find.text('Chưa có khoản nào'), findsOneWidget);
      // Section "Tổng ròng" cũng không hiện vì không có transfer
      expect(find.text('Tổng ròng'), findsNothing);
    },
  );

  testWidgets(
    'không render khi tất cả match có matchCost null/0',
    (tester) async {
      await tester.pumpWidget(_wrap(CostSummaryPanel(
        league: _league(),
        sortedStats: [_stat('A', 'Alice'), _stat('B', 'Bob')],
        matches: [
          _match(home: 'A', away: 'B', homeScore: 1, awayScore: 0),
          _match(
              home: 'A', away: 'B', homeScore: 1, awayScore: 0, matchCost: 0),
        ],
      )));

      expect(find.text('Chi phí'), findsNothing);
    },
  );

  testWidgets(
    'rank + match cost cộng dồn vào net per-user',
    (tester) async {
      // Alice rank 1 (nhận 50k từ B). B thắng A 1 trận với cost 30k.
      // Net Alice: +50k -30k = +20k
      // Net Bob: -50k +30k = -20k
      await tester.pumpWidget(_wrap(CostSummaryPanel(
        league: _league(
          rankPayoutEnabled: true,
          rankPayouts: const [50000],
          status: GNEsportLeagueStatus.finished.value,
        ),
        sortedStats: [
          _stat('A', 'Alice', wins: 1),
          _stat('B', 'Bob', wins: 1),
        ],
        matches: [
          _match(home: 'B', away: 'A', homeScore: 2, awayScore: 0,
              matchCost: 30000),
        ],
      )));

      expect(find.text('+20k'), findsOneWidget);
      expect(find.text('-20k'), findsOneWidget);
    },
  );

  testWidgets(
    'bracket mode: bracketRankPayouts tính từ knockout matches',
    (tester) async {
      // Cup 4 người: semi(r=0) → final(r=1). Champion=A, runner-up=B, losers C,D
      final knockoutMatches = [
        _match(home: 'A', away: 'C', homeScore: 2, awayScore: 0, knockoutRound: 0,
            homeTeam: _user('A', 'Alice'), awayTeam: _user('C', 'Charlie')),
        _match(home: 'B', away: 'D', homeScore: 1, awayScore: 0, knockoutRound: 0,
            homeTeam: _user('B', 'Bob'), awayTeam: _user('D', 'Dave')),
        _match(home: 'A', away: 'B', homeScore: 2, awayScore: 1, knockoutRound: 1,
            homeTeam: _user('A', 'Alice'), awayTeam: _user('B', 'Bob')),
      ];
      await tester.pumpWidget(_wrap(CostSummaryPanel(
        league: _league(rankPayoutEnabled: true, rankPayouts: [100000, 50000]),
        sortedStats: const [],
        matches: const [],
        isBracketMode: true,
        knockoutMatches: knockoutMatches,
      )));

      expect(find.text('Chi phí'), findsOneWidget);
      // Runner-up (B=Bob) trả 100k
      expect(find.text('100k'), findsOneWidget);
      // Semi-losers C,D trả 50k mỗi người → 2 dòng 50k
      expect(find.text('50k'), findsNWidgets(2));
    },
  );

  testWidgets(
    'bracket mode: final chưa xong → không có transfer rank',
    (tester) async {
      final knockoutMatches = [
        _match(home: 'A', away: 'B', homeScore: null, awayScore: null,
            isFinished: false, knockoutRound: 0),
      ];
      await tester.pumpWidget(_wrap(CostSummaryPanel(
        league: _league(rankPayoutEnabled: true, rankPayouts: [100000]),
        sortedStats: const [],
        matches: const [],
        isBracketMode: true,
        knockoutMatches: knockoutMatches,
      )));

      expect(find.text('Chưa có khoản nào'), findsOneWidget);
    },
  );

  testWidgets(
    'fallback display name khi user là null (đề phòng dữ liệu cũ)',
    (tester) async {
      // sortedStat KHÔNG có user attached → fallback
      final stats = [
        GNEsportLeagueStat(
          id: 'S_X',
          userId: 'X',
          leagueId: 'L1',
          matchesPlayed: 1,
          goals: 1,
          goalsConceded: 0,
          wins: 1,
          draws: 0,
          losses: 0,
        ),
        GNEsportLeagueStat(
          id: 'S_Y',
          userId: 'Y',
          leagueId: 'L1',
          matchesPlayed: 1,
          goals: 0,
          goalsConceded: 1,
          wins: 0,
          draws: 0,
          losses: 1,
        ),
      ];
      await tester.pumpWidget(_wrap(CostSummaryPanel(
        league: _league(
          rankPayoutEnabled: true,
          rankPayouts: const [50000],
          status: GNEsportLeagueStatus.finished.value,
        ),
        sortedStats: stats,
        matches: const [],
      )));

      // Hai dòng "Người chơi" (placeholder name) — ít nhất 2.
      expect(find.text('Người chơi'), findsAtLeastNWidgets(2));
    },
  );
}
