import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/user/stats/gn_user_h2h.dart';

void main() {
  group('GNUserH2H', () {
    test('empty defaults', () {
      final h = GNUserH2H.empty(userId: 'u1', opponentId: 'u2');
      expect(h.matchesPlayed, 0);
      expect(h.wins, 0);
      expect(h.lastMetAt, isNull);
      expect(h.opponentDisplayName, '');
      expect(h.winRate, isNull);
      expect(h.goalDifference, 0);
    });

    test('fromMap → toMap round-trip', () {
      final original = GNUserH2H(
        userId: 'u1',
        opponentId: 'u2',
        opponentDisplayName: 'Player 2',
        matchesPlayed: 5,
        wins: 3,
        draws: 1,
        losses: 1,
        goals: 9,
        goalsConceded: 4,
        lastMetAt: DateTime(2026, 4, 1),
        updatedAt: DateTime(2026, 5, 1),
      );
      final restored = GNUserH2H.fromMap(
        original.toMap(),
        userId: 'u1',
        opponentId: 'u2',
      );
      expect(restored.opponentDisplayName, 'Player 2');
      expect(restored.matchesPlayed, 5);
      expect(restored.wins, 3);
      expect(restored.lastMetAt, DateTime(2026, 4, 1));
      expect(restored.winRate, closeTo(0.6, 1e-9));
      expect(restored.goalDifference, 5);
    });

    test('toMap encode datetime thành Timestamp; null vẫn là null', () {
      final h = GNUserH2H.empty(userId: 'u1', opponentId: 'u2');
      final map = h.toMap();
      expect(map[GNUserH2H.fieldLastMetAt], isNull);
      expect(map[GNUserH2H.fieldUpdatedAt], isNull);

      final filled = GNUserH2H(
        userId: 'u1',
        opponentId: 'u2',
        opponentDisplayName: '',
        matchesPlayed: 0,
        wins: 0,
        draws: 0,
        losses: 0,
        goals: 0,
        goalsConceded: 0,
        lastMetAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );
      final fmap = filled.toMap();
      expect(fmap[GNUserH2H.fieldLastMetAt], isA<Timestamp>());
      expect(fmap[GNUserH2H.fieldUpdatedAt], isA<Timestamp>());
    });

    test('fromMap khi missing keys', () {
      final h = GNUserH2H.fromMap(
        <String, dynamic>{},
        userId: 'u1',
        opponentId: 'u2',
      );
      expect(h.matchesPlayed, 0);
      expect(h.opponentDisplayName, '');
    });

    test('Equatable props — equality theo từng field', () {
      final a = GNUserH2H.empty(userId: 'u1', opponentId: 'u2');
      final b = GNUserH2H.empty(userId: 'u1', opponentId: 'u2');
      expect(a, equals(b));
      expect(a.props.length, 11);
    });
  });
}
