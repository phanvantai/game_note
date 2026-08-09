import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/round_robin_scheduler.dart';

void main() {
  GNEsportMatch matchOf(ScheduledPairing pairing) {
    return GNEsportMatch(
      id: '${pairing.homeId}-${pairing.awayId}-${pairing.matchday}',
      homeTeamId: pairing.homeId,
      awayTeamId: pairing.awayId,
      date: DateTime(2026, 5, 10),
      isFinished: false,
      leagueId: 'L1',
      matchday: pairing.matchday,
    );
  }

  String pairKey(String a, String b) {
    final sorted = [a, b]..sort();
    return sorted.join('|');
  }

  group('buildRoundRobinSchedule - số vòng và số trận', () {
    test('6 người chơi tạo 5 vòng, mỗi vòng 3 trận', () {
      final schedule = buildRoundRobinSchedule(
        teamIds: const ['u1', 'u2', 'u3', 'u4', 'u5', 'u6'],
        existingMatches: const [],
      );

      expect(schedule, hasLength(15));

      final byMatchday = <int, List<ScheduledPairing>>{};
      for (final pairing in schedule) {
        byMatchday.putIfAbsent(pairing.matchday, () => []).add(pairing);
      }

      expect(byMatchday.keys.toList()..sort(), [1, 2, 3, 4, 5]);
      for (final matches in byMatchday.values) {
        expect(matches, hasLength(3));
      }
    });

    test('mỗi cặp người chơi gặp nhau đúng một lần', () {
      final schedule = buildRoundRobinSchedule(
        teamIds: const ['u1', 'u2', 'u3', 'u4', 'u5', 'u6'],
        existingMatches: const [],
      );

      final pairs = schedule.map((p) => pairKey(p.homeId, p.awayId)).toList();

      expect(pairs.toSet(), hasLength(15));
    });

    test('mỗi người chơi đá đúng một trận trong mỗi vòng', () {
      final schedule = buildRoundRobinSchedule(
        teamIds: const ['u1', 'u2', 'u3', 'u4', 'u5', 'u6'],
        existingMatches: const [],
      );

      final byMatchday = <int, List<ScheduledPairing>>{};
      for (final pairing in schedule) {
        byMatchday.putIfAbsent(pairing.matchday, () => []).add(pairing);
      }

      for (final entry in byMatchday.entries) {
        final playing = <String>[];
        for (final pairing in entry.value) {
          playing.addAll([pairing.homeId, pairing.awayId]);
        }
        expect(
          playing.toSet(),
          hasLength(6),
          reason: 'vòng ${entry.key} có người đá hai trận',
        );
      }
    });

    test('5 người chơi tạo 5 vòng, mỗi vòng một người nghỉ', () {
      final schedule = buildRoundRobinSchedule(
        teamIds: const ['u1', 'u2', 'u3', 'u4', 'u5'],
        existingMatches: const [],
      );

      expect(schedule, hasLength(10));

      final byMatchday = <int, List<ScheduledPairing>>{};
      for (final pairing in schedule) {
        byMatchday.putIfAbsent(pairing.matchday, () => []).add(pairing);
      }

      expect(byMatchday.keys.toList()..sort(), [1, 2, 3, 4, 5]);
      for (final matches in byMatchday.values) {
        expect(matches, hasLength(2));
      }
    });

    test('2 người chơi tạo 1 vòng 1 trận', () {
      final schedule = buildRoundRobinSchedule(
        teamIds: const ['u1', 'u2'],
        existingMatches: const [],
      );

      expect(schedule, hasLength(1));
      expect(schedule.single.matchday, 1);
    });

    test('vòng đấu được đánh số từ 1 theo từng lượt', () {
      final schedule = buildRoundRobinSchedule(
        teamIds: const ['u1', 'u2', 'u3', 'u4'],
        existingMatches: const [],
      );

      expect(
        schedule.map((p) => p.matchday).reduce((a, b) => a < b ? a : b),
        1,
      );
      expect(
        schedule.map((p) => p.matchday).reduce((a, b) => a > b ? a : b),
        3,
      );
    });
  });

  group('buildRoundRobinSchedule - đảo sân', () {
    test('lượt thứ hai đảo sân nhà so với lượt đầu', () {
      final firstLeg = buildRoundRobinSchedule(
        teamIds: const ['u1', 'u2', 'u3', 'u4'],
        existingMatches: const [],
      );

      final secondLeg = buildRoundRobinSchedule(
        teamIds: const ['u1', 'u2', 'u3', 'u4'],
        existingMatches: firstLeg.map(matchOf).toList(),
      );

      final firstHome = {
        for (final p in firstLeg) pairKey(p.homeId, p.awayId): p.homeId,
      };

      expect(secondLeg, hasLength(firstLeg.length));
      for (final pairing in secondLeg) {
        expect(
          pairing.homeId,
          isNot(firstHome[pairKey(pairing.homeId, pairing.awayId)]),
          reason: 'cặp ${pairing.homeId} vs ${pairing.awayId} chưa đảo sân',
        );
      }
    });

    test('lượt thứ ba trả sân nhà về như lượt đầu', () {
      final firstLeg = buildRoundRobinSchedule(
        teamIds: const ['u1', 'u2', 'u3', 'u4'],
        existingMatches: const [],
      );
      final secondLeg = buildRoundRobinSchedule(
        teamIds: const ['u1', 'u2', 'u3', 'u4'],
        existingMatches: firstLeg.map(matchOf).toList(),
      );
      final thirdLeg = buildRoundRobinSchedule(
        teamIds: const ['u1', 'u2', 'u3', 'u4'],
        existingMatches: [...firstLeg, ...secondLeg].map(matchOf).toList(),
      );

      final firstHome = {
        for (final p in firstLeg) pairKey(p.homeId, p.awayId): p.homeId,
      };

      for (final pairing in thirdLeg) {
        expect(
          pairing.homeId,
          firstHome[pairKey(pairing.homeId, pairing.awayId)],
          reason: 'cặp ${pairing.homeId} vs ${pairing.awayId} sai chiều sân',
        );
      }
    });

    test('cặp chưa từng gặp nhau không bị ảnh hưởng bởi trận của cặp khác', () {
      // u3 mới tham gia: u1-u2 đã đá, u3 chưa đá trận nào.
      final existing = [
        GNEsportMatch(
          id: 'm1',
          homeTeamId: 'u1',
          awayTeamId: 'u2',
          date: DateTime(2026, 5, 10),
          isFinished: false,
          leagueId: 'L1',
          matchday: 1,
        ),
      ];

      final schedule = buildRoundRobinSchedule(
        teamIds: const ['u1', 'u2', 'u3'],
        existingMatches: existing,
      );

      final u1u2 = schedule.firstWhere(
        (p) => pairKey(p.homeId, p.awayId) == pairKey('u1', 'u2'),
      );
      expect(u1u2.homeId, 'u2', reason: 'cặp đã đá phải đảo sân');

      final u1u3 = schedule.firstWhere(
        (p) => pairKey(p.homeId, p.awayId) == pairKey('u1', 'u3'),
      );
      expect(u1u3.homeId, isNotNull);
      expect({u1u3.homeId, u1u3.awayId}, {'u1', 'u3'});
    });

    test('bỏ qua trận của cặp khác khi đếm sân nhà', () {
      final existing = [
        GNEsportMatch(
          id: 'm1',
          homeTeamId: 'u1',
          awayTeamId: 'u3',
          date: DateTime(2026, 5, 10),
          isFinished: false,
          leagueId: 'L1',
          matchday: 1,
        ),
      ];

      final schedule = buildRoundRobinSchedule(
        teamIds: const ['u1', 'u2'],
        existingMatches: existing,
      );

      expect(schedule.single.homeId, 'u1');
      expect(schedule.single.awayId, 'u2');
    });
  });

  group('buildRoundRobinSchedule - đầu vào bất thường', () {
    test('loại bỏ id trùng lặp', () {
      final schedule = buildRoundRobinSchedule(
        teamIds: const ['u1', 'u1', 'u2'],
        existingMatches: const [],
      );

      expect(schedule, hasLength(1));
      expect({schedule.single.homeId, schedule.single.awayId}, {'u1', 'u2'});
    });

    test('loại bỏ id rỗng', () {
      final schedule = buildRoundRobinSchedule(
        teamIds: const ['u1', '', 'u2'],
        existingMatches: const [],
      );

      expect(schedule, hasLength(1));
    });

    test('ít hơn 2 người chơi trả về danh sách rỗng', () {
      expect(
        buildRoundRobinSchedule(
          teamIds: const ['u1'],
          existingMatches: const [],
        ),
        isEmpty,
      );
      expect(
        buildRoundRobinSchedule(teamIds: const [], existingMatches: const []),
        isEmpty,
      );
    });
  });

  group('ScheduledPairing', () {
    test('so sánh bằng giá trị', () {
      const a = ScheduledPairing(homeId: 'u1', awayId: 'u2', matchday: 1);
      const b = ScheduledPairing(homeId: 'u1', awayId: 'u2', matchday: 1);
      const c = ScheduledPairing(homeId: 'u2', awayId: 'u1', matchday: 1);

      expect(a, b);
      expect(a, isNot(c));
      expect(a.toString(), contains('u1'));
    });
  });

  group('shouldFlipForMissedLegs', () {
    // Orientation is computed from a read taken before the transaction. If
    // another client allocated legs in between, this decides whether the
    // schedule we already built is still on the right side of the alternation.
    test('không có lượt nào chen vào thì giữ nguyên chiều sân', () {
      expect(
        shouldFlipForMissedLegs(
          expectedAllocated: 5,
          actualAllocated: 5,
          matchdaysInLeg: 5,
        ),
        isFalse,
      );
    });

    test('một lượt chen vào thì đảo chiều sân', () {
      expect(
        shouldFlipForMissedLegs(
          expectedAllocated: 5,
          actualAllocated: 10,
          matchdaysInLeg: 5,
        ),
        isTrue,
      );
    });

    test('hai lượt chen vào thì giữ nguyên', () {
      expect(
        shouldFlipForMissedLegs(
          expectedAllocated: 5,
          actualAllocated: 15,
          matchdaysInLeg: 5,
        ),
        isFalse,
      );
    });

    test('ba lượt chen vào thì đảo', () {
      expect(
        shouldFlipForMissedLegs(
          expectedAllocated: 0,
          actualAllocated: 15,
          matchdaysInLeg: 5,
        ),
        isTrue,
      );
    });

    test('counter lùi lại (không nên xảy ra) thì giữ nguyên', () {
      expect(
        shouldFlipForMissedLegs(
          expectedAllocated: 10,
          actualAllocated: 5,
          matchdaysInLeg: 5,
        ),
        isFalse,
      );
    });

    test('lệch nhỏ hơn một lượt trọn vẹn thì giữ nguyên', () {
      expect(
        shouldFlipForMissedLegs(
          expectedAllocated: 5,
          actualAllocated: 8,
          matchdaysInLeg: 5,
        ),
        isFalse,
      );
    });

    test('matchdaysInLeg bằng 0 thì giữ nguyên, không chia cho 0', () {
      expect(
        shouldFlipForMissedLegs(
          expectedAllocated: 0,
          actualAllocated: 5,
          matchdaysInLeg: 0,
        ),
        isFalse,
      );
    });
  });

  group('flipPairings', () {
    test('đảo sân nhà/sân khách, giữ nguyên số vòng', () {
      const schedule = [
        ScheduledPairing(homeId: 'u1', awayId: 'u2', matchday: 1),
        ScheduledPairing(homeId: 'u3', awayId: 'u4', matchday: 2),
      ];

      expect(flipPairings(schedule), [
        const ScheduledPairing(homeId: 'u2', awayId: 'u1', matchday: 1),
        const ScheduledPairing(homeId: 'u4', awayId: 'u3', matchday: 2),
      ]);
    });

    test('danh sách rỗng trả về rỗng', () {
      expect(flipPairings(const []), isEmpty);
    });
  });
}
