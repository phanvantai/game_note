import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/presentation/esport/tournament/cost/cost_calculator.dart';

GNEsportLeagueStat _stat(
  String userId, {
  int wins = 0,
  int draws = 0,
  int losses = 0,
  int goals = 0,
  int goalsConceded = 0,
}) {
  return GNEsportLeagueStat(
    id: 'stat_$userId',
    userId: userId,
    leagueId: 'L',
    matchesPlayed: wins + draws + losses,
    goals: goals,
    goalsConceded: goalsConceded,
    wins: wins,
    draws: draws,
    losses: losses,
  );
}

GNEsportMatch _match({
  required String home,
  required String away,
  int? homeScore,
  int? awayScore,
  bool isFinished = true,
  int? matchCost,
  int? costPerGoal,
  int? knockoutRound,
}) {
  return GNEsportMatch(
    id: '$home-$away-${knockoutRound ?? ''}',
    homeTeamId: home,
    awayTeamId: away,
    homeScore: homeScore,
    awayScore: awayScore,
    date: DateTime(2026, 1, 1),
    isFinished: isFinished,
    leagueId: 'L',
    matchCost: matchCost,
    costPerGoal: costPerGoal,
    knockoutRound: knockoutRound,
    phase: knockoutRound != null ? 'knockout' : null,
  );
}

void main() {
  group('CostCalculator.rankPayouts', () {
    test(
      'chia tiền theo cấu hình 4 người: 50/100/150 → hạng nhất nhận 300',
      () {
        // sorted: A(rank1) > B(rank2) > C(rank3) > D(rank4)
        final stats = [
          _stat('A', wins: 3, goals: 9, goalsConceded: 0),
          _stat('B', wins: 2, losses: 1, goals: 6, goalsConceded: 3),
          _stat('C', wins: 1, losses: 2, goals: 3, goalsConceded: 6),
          _stat('D', losses: 3, goals: 0, goalsConceded: 9),
        ];
        final transfers = CostCalculator.rankPayouts(stats, [
          50000,
          100000,
          150000,
        ]);

        expect(transfers, hasLength(3));
        // Tất cả chuyển về A (hạng nhất)
        expect(transfers.every((t) => t.toUserId == 'A'), isTrue);
        // Hạng 2 trả 50k, hạng 3 trả 100k, hạng 4 trả 150k
        expect(transfers.firstWhere((t) => t.fromUserId == 'B').amount, 50000);
        expect(transfers.firstWhere((t) => t.fromUserId == 'C').amount, 100000);
        expect(transfers.firstWhere((t) => t.fromUserId == 'D').amount, 150000);
      },
    );

    test('rankPayouts ngắn hơn số người: hạng dưới không phải trả', () {
      final stats = [
        _stat('A', wins: 3),
        _stat('B', wins: 2),
        _stat('C', wins: 1),
        _stat('D'),
      ];
      // Chỉ có 2 mức (cho hạng 2, 3). Hạng 4 trả 0 → không có transfer.
      final transfers = CostCalculator.rankPayouts(stats, [50000, 100000]);
      expect(transfers, hasLength(2));
      expect(transfers.any((t) => t.fromUserId == 'D'), isFalse);
    });

    test('rankPayouts dài hơn số người: cắt phần thừa', () {
      final stats = [_stat('A', wins: 1), _stat('B')];
      final transfers = CostCalculator.rankPayouts(stats, [
        50000,
        100000,
        150000,
      ]);
      expect(transfers, hasLength(1));
      expect(transfers.first.fromUserId, 'B');
      expect(transfers.first.amount, 50000);
    });

    test('chỉ 1 người: không có transfer', () {
      expect(CostCalculator.rankPayouts([_stat('A')], [50000]), isEmpty);
    });

    test('rankPayouts rỗng: không có transfer', () {
      expect(
        CostCalculator.rankPayouts([_stat('A', wins: 1), _stat('B')], const []),
        isEmpty,
      );
    });

    test('amount = 0 trong list: skip rank đó', () {
      final stats = [_stat('A', wins: 2), _stat('B'), _stat('C')];
      final transfers = CostCalculator.rankPayouts(stats, [0, 100000]);
      expect(transfers, hasLength(1));
      expect(transfers.first.fromUserId, 'C');
    });
  });

  group('CostCalculator.matchCosts', () {
    test('1 trận finished, có cost: thua trả thắng', () {
      final transfers = CostCalculator.matchCosts([
        _match(
          home: 'A',
          away: 'B',
          homeScore: 2,
          awayScore: 1,
          matchCost: 50000,
        ),
      ]);
      expect(transfers, hasLength(1));
      expect(transfers.first.fromUserId, 'B'); // B thua
      expect(transfers.first.toUserId, 'A');
      expect(transfers.first.amount, 50000);
    });

    test('hoà: skip', () {
      final transfers = CostCalculator.matchCosts([
        _match(
          home: 'A',
          away: 'B',
          homeScore: 1,
          awayScore: 1,
          matchCost: 50000,
        ),
      ]);
      expect(transfers, isEmpty);
    });

    test('matchCost null: skip', () {
      final transfers = CostCalculator.matchCosts([
        _match(home: 'A', away: 'B', homeScore: 2, awayScore: 0),
      ]);
      expect(transfers, isEmpty);
    });

    test('matchCost = 0: skip', () {
      final transfers = CostCalculator.matchCosts([
        _match(home: 'A', away: 'B', homeScore: 2, awayScore: 0, matchCost: 0),
      ]);
      expect(transfers, isEmpty);
    });

    test('chưa finished: skip', () {
      final transfers = CostCalculator.matchCosts([
        _match(
          home: 'A',
          away: 'B',
          homeScore: 2,
          awayScore: 0,
          matchCost: 50000,
          isFinished: false,
        ),
      ]);
      expect(transfers, isEmpty);
    });

    test(
      'netting: A thắng B 2 trận, B thắng A 1 trận, cùng 50k → còn A nhận 50k',
      () {
        final transfers = CostCalculator.matchCosts([
          _match(
            home: 'A',
            away: 'B',
            homeScore: 2,
            awayScore: 0,
            matchCost: 50000,
          ),
          _match(
            home: 'B',
            away: 'A',
            homeScore: 0,
            awayScore: 1,
            matchCost: 50000,
          ),
          _match(
            home: 'A',
            away: 'B',
            homeScore: 1,
            awayScore: 3,
            matchCost: 50000,
          ),
        ]);
        expect(transfers, hasLength(1));
        expect(transfers.first.fromUserId, 'B');
        expect(transfers.first.toUserId, 'A');
        expect(transfers.first.amount, 50000);
      },
    );

    test('netting hoàn toàn (1-1): không có transfer', () {
      final transfers = CostCalculator.matchCosts([
        _match(
          home: 'A',
          away: 'B',
          homeScore: 2,
          awayScore: 0,
          matchCost: 50000,
        ),
        _match(
          home: 'B',
          away: 'A',
          homeScore: 1,
          awayScore: 0,
          matchCost: 50000,
        ),
      ]);
      expect(transfers, isEmpty);
    });

    test(
      'cost khác nhau giữa 2 trận: cộng theo từng trận trước khi netting',
      () {
        final transfers = CostCalculator.matchCosts([
          _match(
            home: 'A',
            away: 'B',
            homeScore: 2,
            awayScore: 0,
            matchCost: 50000,
          ),
          _match(
            home: 'A',
            away: 'B',
            homeScore: 0,
            awayScore: 1,
            matchCost: 100000,
          ),
        ]);
        // Trận 1: B trả A 50k. Trận 2: A trả B 100k. Net: A trả B 50k.
        expect(transfers, hasLength(1));
        expect(transfers.first.fromUserId, 'A');
        expect(transfers.first.toUserId, 'B');
        expect(transfers.first.amount, 50000);
      },
    );

    test('nhiều cặp: mỗi cặp tính độc lập', () {
      final transfers = CostCalculator.matchCosts([
        _match(
          home: 'A',
          away: 'B',
          homeScore: 2,
          awayScore: 0,
          matchCost: 50000,
        ),
        _match(
          home: 'C',
          away: 'D',
          homeScore: 0,
          awayScore: 3,
          matchCost: 100000,
        ),
      ]);
      expect(transfers, hasLength(2));
      final ab = transfers.firstWhere(
        (t) => {t.fromUserId, t.toUserId}.containsAll({'A', 'B'}),
      );
      expect(ab.fromUserId, 'B');
      expect(ab.amount, 50000);
      final cd = transfers.firstWhere(
        (t) => {t.fromUserId, t.toUserId}.containsAll({'C', 'D'}),
      );
      expect(cd.fromUserId, 'C');
      expect(cd.amount, 100000);
    });

    test('per-goal addon: 3-1 với base 50k + perGoal 50k → loser trả 150k', () {
      final transfers = CostCalculator.matchCosts([
        _match(
          home: 'A',
          away: 'B',
          homeScore: 3,
          awayScore: 1,
          matchCost: 50000,
          costPerGoal: 50000,
        ),
      ]);
      expect(transfers, hasLength(1));
      expect(transfers.first.fromUserId, 'B');
      expect(transfers.first.toUserId, 'A');
      expect(transfers.first.amount, 50000 + 2 * 50000);
    });

    test('per-goal addon: hoà 2-2 vẫn skip dù costPerGoal > 0', () {
      final transfers = CostCalculator.matchCosts([
        _match(
          home: 'A',
          away: 'B',
          homeScore: 2,
          awayScore: 2,
          matchCost: 50000,
          costPerGoal: 50000,
        ),
      ]);
      expect(transfers, isEmpty);
    });

    test('per-goal addon: matchCost=0 vẫn skip dù costPerGoal > 0', () {
      final transfers = CostCalculator.matchCosts([
        _match(
          home: 'A',
          away: 'B',
          homeScore: 3,
          awayScore: 0,
          matchCost: 0,
          costPerGoal: 50000,
        ),
      ]);
      expect(transfers, isEmpty);
    });

    test('per-goal addon: costPerGoal null → chỉ tính base', () {
      final transfers = CostCalculator.matchCosts([
        _match(
          home: 'A',
          away: 'B',
          homeScore: 5,
          awayScore: 0,
          matchCost: 50000,
        ),
      ]);
      expect(transfers, hasLength(1));
      expect(transfers.first.amount, 50000);
    });

    test('per-goal addon: netting same pair với 2 trận khác hiệu số', () {
      // Trận 1: A thắng B 3-0 → B trả 50k + 3*50k = 200k
      // Trận 2: B thắng A 1-0 → A trả 50k + 1*50k = 100k
      // Net: B trả A 100k
      final transfers = CostCalculator.matchCosts([
        _match(
          home: 'A',
          away: 'B',
          homeScore: 3,
          awayScore: 0,
          matchCost: 50000,
          costPerGoal: 50000,
        ),
        _match(
          home: 'B',
          away: 'A',
          homeScore: 1,
          awayScore: 0,
          matchCost: 50000,
          costPerGoal: 50000,
        ),
      ]);
      expect(transfers, hasLength(1));
      expect(transfers.first.fromUserId, 'B');
      expect(transfers.first.toUserId, 'A');
      expect(transfers.first.amount, 100000);
    });
  });

  group('CostCalculator.bracketRankPayouts', () {
    // Cup 4 người: semi(round=0) → final(round=1)
    // A thắng C ở semi, B thắng D ở semi → final: A thắng B
    // Champion=A, runner-up=B, semi-losers=C,D
    List<GNEsportMatch> cup4() => [
      _match(
        home: 'A',
        away: 'C',
        homeScore: 2,
        awayScore: 0,
        knockoutRound: 0,
      ),
      _match(
        home: 'B',
        away: 'D',
        homeScore: 1,
        awayScore: 0,
        knockoutRound: 0,
      ),
      _match(
        home: 'A',
        away: 'B',
        homeScore: 2,
        awayScore: 1,
        knockoutRound: 1,
      ),
    ];

    test('4 người, 2 mức: runner-up + mỗi semi-loser trả đúng', () {
      final transfers = CostCalculator.bracketRankPayouts(cup4(), [
        100000,
        50000,
      ]);

      expect(transfers, hasLength(3));
      // Champion = A
      expect(transfers.every((t) => t.toUserId == 'A'), isTrue);
      // Runner-up B trả 100k
      expect(transfers.firstWhere((t) => t.fromUserId == 'B').amount, 100000);
      // Semi-losers C, D mỗi người trả 50k
      expect(transfers.firstWhere((t) => t.fromUserId == 'C').amount, 50000);
      expect(transfers.firstWhere((t) => t.fromUserId == 'D').amount, 50000);
    });

    test('chỉ 1 mức (runner-up): C và D không phải trả', () {
      final transfers = CostCalculator.bracketRankPayouts(cup4(), [100000]);
      expect(transfers, hasLength(1));
      expect(transfers.first.fromUserId, 'B');
      expect(transfers.first.amount, 100000);
    });

    test('final chưa finished: trả về rỗng', () {
      final matches = [
        _match(
          home: 'A',
          away: 'C',
          homeScore: 2,
          awayScore: 0,
          knockoutRound: 0,
        ),
        _match(
          home: 'A',
          away: 'B',
          homeScore: null,
          awayScore: null,
          isFinished: false,
          knockoutRound: 1,
        ),
      ];
      expect(CostCalculator.bracketRankPayouts(matches, [100000]), isEmpty);
    });

    test('final hoà: trả về rỗng', () {
      final matches = [
        _match(
          home: 'A',
          away: 'B',
          homeScore: 1,
          awayScore: 1,
          knockoutRound: 0,
        ),
      ];
      expect(CostCalculator.bracketRankPayouts(matches, [100000]), isEmpty);
    });

    test('rankPayouts rỗng: trả về rỗng', () {
      expect(CostCalculator.bracketRankPayouts(cup4(), []), isEmpty);
    });

    test('knockoutMatches rỗng: trả về rỗng', () {
      expect(CostCalculator.bracketRankPayouts([], [100000]), isEmpty);
    });

    test('amount = 0 trong list: skip mức đó', () {
      final transfers = CostCalculator.bracketRankPayouts(cup4(), [100000, 0]);
      // Chỉ runner-up (B) trả; C,D skip vì amount=0
      expect(transfers, hasLength(1));
      expect(transfers.first.fromUserId, 'B');
    });

    test('semi match chưa finished: semi-loser không tính', () {
      final matches = [
        _match(
          home: 'A',
          away: 'C',
          homeScore: 2,
          awayScore: 0,
          knockoutRound: 0,
        ),
        // B vs D chưa xong
        _match(
          home: 'B',
          away: 'D',
          homeScore: null,
          awayScore: null,
          isFinished: false,
          knockoutRound: 0,
        ),
        _match(
          home: 'A',
          away: 'B',
          homeScore: 2,
          awayScore: 1,
          knockoutRound: 1,
        ),
      ];
      final transfers = CostCalculator.bracketRankPayouts(matches, [
        100000,
        50000,
      ]);
      // Runner-up B: 100k; Semi-loser C: 50k; D không tính (match chưa xong)
      expect(transfers.any((t) => t.fromUserId == 'D'), isFalse);
      expect(transfers.firstWhere((t) => t.fromUserId == 'B').amount, 100000);
      expect(transfers.firstWhere((t) => t.fromUserId == 'C').amount, 50000);
    });
  });

  group('CostCalculator.netByUser', () {
    test('tổng ròng nhiều bên', () {
      final transfers = [
        const CostTransfer(fromUserId: 'B', toUserId: 'A', amount: 50000),
        const CostTransfer(fromUserId: 'C', toUserId: 'A', amount: 100000),
        const CostTransfer(fromUserId: 'D', toUserId: 'B', amount: 30000),
      ];
      final net = CostCalculator.netByUser(transfers);
      expect(net['A'], 150000); // nhận từ B + C
      expect(net['B'], -20000); // -50k + 30k
      expect(net['C'], -100000);
      expect(net['D'], -30000);
    });

    test('list rỗng: map rỗng', () {
      expect(CostCalculator.netByUser(const []), isEmpty);
    });

    test('tổng zero-sum', () {
      final transfers = [
        const CostTransfer(fromUserId: 'A', toUserId: 'B', amount: 100),
        const CostTransfer(fromUserId: 'B', toUserId: 'C', amount: 200),
        const CostTransfer(fromUserId: 'C', toUserId: 'A', amount: 50),
      ];
      final net = CostCalculator.netByUser(transfers);
      expect(net.values.fold<int>(0, (a, b) => a + b), 0);
    });
  });
}
