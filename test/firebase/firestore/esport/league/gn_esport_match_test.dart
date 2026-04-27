import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';

GNEsportMatch _match({int? matchCost}) {
  return GNEsportMatch(
    id: 'M1',
    homeTeamId: 'A',
    awayTeamId: 'B',
    homeScore: 2,
    awayScore: 1,
    date: DateTime(2026, 1, 1),
    isFinished: true,
    leagueId: 'L1',
    medals: 0,
    matchCost: matchCost,
  );
}

void main() {
  group('GNEsportMatch.toMap', () {
    test('persist matchCost (số dương)', () {
      final map = _match(matchCost: 100000).toMap();
      expect(map[GNEsportMatch.fieldMatchCost], 100000);
    });

    test('persist matchCost = 0 (user tắt cost cho trận này)', () {
      final map = _match(matchCost: 0).toMap();
      expect(map.containsKey(GNEsportMatch.fieldMatchCost), isTrue);
      expect(map[GNEsportMatch.fieldMatchCost], 0);
    });

    test('matchCost null vẫn lưu (cho phép Firestore distinguish unset)', () {
      final map = _match(matchCost: null).toMap();
      expect(map.containsKey(GNEsportMatch.fieldMatchCost), isTrue);
      expect(map[GNEsportMatch.fieldMatchCost], isNull);
    });
  });

  group('GNEsportMatch.fromMap', () {
    test('roundtrip giữ matchCost', () {
      final original = _match(matchCost: 75000);
      final map = Map<String, dynamic>.from(original.toMap());
      map[GNEsportMatch.fieldDate] = original.date; // bypass Timestamp
      final restored = GNEsportMatch.fromMap(map, original.id);
      expect(restored.matchCost, 75000);
    });

    test('document cũ thiếu matchCost: trả về null', () {
      final legacy = <String, dynamic>{
        GNEsportMatch.fieldHomeTeamId: 'A',
        GNEsportMatch.fieldAwayTeamId: 'B',
        GNEsportMatch.fieldHomeScore: 1,
        GNEsportMatch.fieldAwayScore: 0,
        GNEsportMatch.fieldDate: DateTime(2025, 1, 1),
        GNEsportMatch.fieldIsFinished: true,
        GNEsportMatch.fieldLeagueId: 'L1',
        // không có matchCost
      };
      final restored = GNEsportMatch.fromMap(legacy, 'old');
      expect(restored.matchCost, isNull);
    });
  });

  group('copyWith semantics', () {
    test('copyWith(matchCost: 0) tắt cost cho trận', () {
      final m = _match(matchCost: 50000).copyWith(matchCost: 0);
      expect(m.matchCost, 0);
    });

    test('copyWith() không truyền matchCost: giữ nguyên giá trị cũ', () {
      final m = _match(matchCost: 50000).copyWith(homeScore: 3);
      expect(m.matchCost, 50000);
      expect(m.homeScore, 3);
    });

    test('override hết các field', () {
      final m = _match().copyWith(
        id: 'X',
        homeTeamId: 'P1',
        awayTeamId: 'P2',
        homeScore: 5,
        awayScore: 3,
        date: DateTime(2027, 1, 1),
        isFinished: false,
        leagueId: 'L9',
        medals: 7,
        matchCost: 99,
      );
      expect(m.id, 'X');
      expect(m.homeTeamId, 'P1');
      expect(m.awayTeamId, 'P2');
      expect(m.homeScore, 5);
      expect(m.awayScore, 3);
      expect(m.date, DateTime(2027, 1, 1));
      expect(m.isFinished, false);
      expect(m.leagueId, 'L9');
      expect(m.medals, 7);
      expect(m.matchCost, 99);
    });

    test('props equality: 2 match cùng data thì equal', () {
      expect(_match(matchCost: 50000) == _match(matchCost: 50000), isTrue);
    });
  });

  group('fromMap fallback', () {
    test('không có date field: rơi vào DateTime.now()', () {
      final data = <String, dynamic>{
        GNEsportMatch.fieldHomeTeamId: 'A',
        GNEsportMatch.fieldAwayTeamId: 'B',
        GNEsportMatch.fieldHomeScore: 0,
        GNEsportMatch.fieldAwayScore: 0,
        GNEsportMatch.fieldIsFinished: false,
        GNEsportMatch.fieldLeagueId: 'L1',
      };
      final restored = GNEsportMatch.fromMap(data, 'x');
      // Không assert chính xác — chỉ verify không crash + có giá trị.
      expect(restored.date, isNotNull);
    });
  });
}
