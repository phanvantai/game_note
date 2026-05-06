import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/user/stats/gn_user_stats_summary.dart';

GNUserRecentMatch _entry(String id, GNRecentMatchResult result) {
  return GNUserRecentMatch(
    matchId: id,
    leagueId: 'l1',
    leagueName: 'Cup',
    date: DateTime(2026, 4, 1),
    userScore: 3,
    opponentScore: 1,
    opponentId: 'u2',
    opponentDisplayName: 'P2',
    result: result,
  );
}

void main() {
  group('GNUserStatsSummary', () {
    test('empty trả về giá trị mặc định 0/empty/null', () {
      final s = GNUserStatsSummary.empty('u1');
      expect(s.userId, 'u1');
      expect(s.matchesPlayed, 0);
      expect(s.recentMatches, isEmpty);
      expect(s.lastChampionAt, isNull);
      expect(s.schemaVersion, GNUserStatsSummary.kCurrentSchemaVersion);
    });

    test('fromMap → toMap round-trip giữ nguyên field', () {
      final original = GNUserStatsSummary(
        userId: 'u1',
        matchesPlayed: 10,
        wins: 6,
        draws: 2,
        losses: 2,
        goals: 18,
        goalsConceded: 9,
        tournamentsJoined: 3,
        tournamentsFinished: 2,
        championCount: 1,
        runnerUpCount: 1,
        lastChampionAt: DateTime(2026, 1, 10),
        recentMatches: [
          _entry('m1', GNRecentMatchResult.win),
          _entry('m2', GNRecentMatchResult.loss),
          _entry('m3', GNRecentMatchResult.draw),
        ],
        updatedAt: DateTime(2026, 5, 1),
        schemaVersion: 1,
      );

      final restored = GNUserStatsSummary.fromMap(original.toMap(), 'u1');
      expect(restored.userId, original.userId);
      expect(restored.matchesPlayed, original.matchesPlayed);
      expect(restored.wins, original.wins);
      expect(restored.draws, original.draws);
      expect(restored.losses, original.losses);
      expect(restored.goals, original.goals);
      expect(restored.goalsConceded, original.goalsConceded);
      expect(restored.lastChampionAt, original.lastChampionAt);
      expect(restored.recentMatches.length, 3);
      expect(restored.recentMatches[0].result, GNRecentMatchResult.win);
      expect(restored.recentMatches[2].result, GNRecentMatchResult.draw);
      expect(restored.schemaVersion, 1);
    });

    test('fromMap dùng default khi field thiếu', () {
      final s = GNUserStatsSummary.fromMap(<String, dynamic>{}, 'u9');
      expect(s.userId, 'u9');
      expect(s.matchesPlayed, 0);
      expect(s.recentMatches, isEmpty);
      expect(s.lastChampionAt, isNull);
    });

    test('toMap mã hoá DateTime thành Timestamp và recent thành list map', () {
      final s = GNUserStatsSummary.empty('u1').copyWithBasic(
        recentMatches: [_entry('m1', GNRecentMatchResult.win)],
        lastChampionAt: DateTime(2026, 2, 2),
      );
      final map = s.toMap();
      expect(map[GNUserStatsSummary.fieldLastChampionAt], isA<Timestamp>());
      final recents = map[GNUserStatsSummary.fieldRecentMatches] as List;
      expect(recents.length, 1);
      expect((recents.first as Map)['result'], 'win');
    });

    test('derived metrics — winRate/championRate/goalDifference', () {
      final empty = GNUserStatsSummary.empty('u1');
      expect(empty.winRate, isNull);
      expect(empty.championRate, isNull);
      expect(empty.runnerUpRate, isNull);
      expect(empty.goalDifference, 0);

      final filled = GNUserStatsSummary(
        userId: 'u1',
        matchesPlayed: 10,
        wins: 6,
        draws: 2,
        losses: 2,
        goals: 18,
        goalsConceded: 9,
        tournamentsJoined: 4,
        tournamentsFinished: 2,
        championCount: 1,
        runnerUpCount: 1,
        lastChampionAt: null,
        recentMatches: const [],
        updatedAt: null,
        schemaVersion: 1,
      );
      expect(filled.winRate, closeTo(0.6, 1e-9));
      expect(filled.championRate, closeTo(0.5, 1e-9));
      expect(filled.runnerUpRate, closeTo(0.5, 1e-9));
      expect(filled.goalDifference, 9);
    });

    test('GNUserRecentMatch fromMap dùng default cho thiếu key + result lạ', () {
      final m = GNUserRecentMatch.fromMap(<String, dynamic>{
        'matchId': 'm1',
        'result': 'unknown',
      });
      expect(m.matchId, 'm1');
      expect(m.result, GNRecentMatchResult.draw);
      expect(m.opponentDisplayName, 'Đối thủ');
      expect(m.date.millisecondsSinceEpoch, 0);
    });

    test('result encoding round-trip win/draw/loss', () {
      for (final r in GNRecentMatchResult.values) {
        final m = _entry('x', r);
        final restored = GNUserRecentMatch.fromMap(m.toMap());
        expect(restored.result, r);
      }
    });

    test('Equatable props — equality phân biệt theo từng field', () {
      final a = GNUserStatsSummary.empty('u1');
      final b = GNUserStatsSummary.empty('u1');
      expect(a, equals(b));
      expect(a.props.length, 17);

      final aRecent = _entry('m', GNRecentMatchResult.win);
      final bRecent = _entry('m', GNRecentMatchResult.win);
      expect(aRecent, equals(bRecent));
      expect(aRecent.props.length, 10);
    });

    test('GNUserRecentMatch lưu updatedAt round-trip', () {
      final m = GNUserRecentMatch(
        matchId: 'm',
        leagueId: 'l',
        leagueName: 'L',
        date: DateTime(2026, 4, 1),
        userScore: 1,
        opponentScore: 0,
        opponentId: 'u2',
        opponentDisplayName: 'P',
        result: GNRecentMatchResult.win,
        updatedAt: DateTime(2026, 5, 10),
      );
      final restored = GNUserRecentMatch.fromMap(m.toMap());
      expect(restored.updatedAt, DateTime(2026, 5, 10));
    });

    test('GNUserLeaguePerformance fromMap/toMap round-trip + derived', () {
      final p = GNUserLeaguePerformance(
        leagueId: 'l1',
        leagueName: 'Cup',
        lastPlayedAt: DateTime(2026, 5, 1),
        matchesPlayed: 10,
        wins: 6,
        draws: 2,
        losses: 2,
        goals: 18,
        goalsConceded: 9,
      );
      final r = GNUserLeaguePerformance.fromMap(p.toMap());
      expect(r.leagueId, 'l1');
      expect(r.matchesPlayed, 10);
      expect(r.lastPlayedAt, DateTime(2026, 5, 1));
      expect(r.pointsPerMatch, closeTo(2.0, 1e-9)); // (6*3+2)/10
      expect(r.goalDifferencePerMatch, closeTo(0.9, 1e-9));
      expect(p.props.length, 9);

      final empty = GNUserLeaguePerformance.fromMap(<String, dynamic>{});
      expect(empty.matchesPlayed, 0);
      expect(empty.pointsPerMatch, isNull);
      expect(empty.goalDifferencePerMatch, isNull);
    });

    test('GNUserOpponentStat fromMap/toMap round-trip', () {
      const o = GNUserOpponentStat(
        opponentId: 'u2',
        opponentDisplayName: 'P2',
        matchesPlayed: 7,
        wins: 3,
        draws: 2,
        losses: 2,
      );
      final r = GNUserOpponentStat.fromMap(o.toMap());
      expect(r, equals(o));
      expect(o.props.length, 6);

      final empty = GNUserOpponentStat.fromMap(<String, dynamic>{});
      expect(empty.matchesPlayed, 0);
      expect(empty.opponentDisplayName, '');
    });

    test('Summary fromMap/toMap mang theo h2hSummary', () {
      final s = GNUserStatsSummary.empty('u1').copyWithH2H([
        const GNUserOpponentStat(
          opponentId: 'u2',
          opponentDisplayName: 'P2',
          matchesPlayed: 5,
          wins: 3,
          draws: 1,
          losses: 1,
        ),
      ]);
      final r = GNUserStatsSummary.fromMap(s.toMap(), 'u1');
      expect(r.h2hSummary.length, 1);
      expect(r.h2hSummary.first.opponentDisplayName, 'P2');
      expect(r.h2hSummary.first.wins, 3);
    });

    test('Summary fromMap/toMap mang theo leagueHistory', () {
      final s = GNUserStatsSummary(
        userId: 'u1',
        matchesPlayed: 0,
        wins: 0,
        draws: 0,
        losses: 0,
        goals: 0,
        goalsConceded: 0,
        tournamentsJoined: 0,
        tournamentsFinished: 0,
        championCount: 0,
        runnerUpCount: 0,
        lastChampionAt: null,
        recentMatches: const [],
        leagueHistory: [
          GNUserLeaguePerformance(
            leagueId: 'l1',
            leagueName: 'Cup A',
            lastPlayedAt: DateTime(2026, 4, 1),
            matchesPlayed: 5,
            wins: 3,
            draws: 1,
            losses: 1,
            goals: 10,
            goalsConceded: 4,
          ),
        ],
        updatedAt: null,
        schemaVersion: 1,
      );
      final r = GNUserStatsSummary.fromMap(s.toMap(), 'u1');
      expect(r.leagueHistory.length, 1);
      expect(r.leagueHistory.first.leagueName, 'Cup A');
      expect(r.leagueHistory.first.wins, 3);
    });

    test('tsToDate xử lý null/Timestamp/DateTime/unknown', () {
      expect(tsToDate(null), isNull);
      expect(tsToDate(Timestamp.fromMillisecondsSinceEpoch(1000)),
          DateTime.fromMillisecondsSinceEpoch(1000));
      expect(tsToDate(DateTime(2026, 1, 1)), DateTime(2026, 1, 1));
      expect(tsToDate('not a date'), isNull);
      expect(tsToDate(42), isNull);
    });
  });
}

extension on GNUserStatsSummary {
  // Tiny helper for tests — copyWith for the few fields we tweak.
  GNUserStatsSummary copyWithBasic({
    List<GNUserRecentMatch>? recentMatches,
    DateTime? lastChampionAt,
  }) {
    return GNUserStatsSummary(
      userId: userId,
      matchesPlayed: matchesPlayed,
      wins: wins,
      draws: draws,
      losses: losses,
      goals: goals,
      goalsConceded: goalsConceded,
      tournamentsJoined: tournamentsJoined,
      tournamentsFinished: tournamentsFinished,
      championCount: championCount,
      runnerUpCount: runnerUpCount,
      lastChampionAt: lastChampionAt ?? this.lastChampionAt,
      recentMatches: recentMatches ?? this.recentMatches,
      updatedAt: updatedAt,
      schemaVersion: schemaVersion,
    );
  }

  GNUserStatsSummary copyWithH2H(List<GNUserOpponentStat> h) {
    return GNUserStatsSummary(
      userId: userId,
      matchesPlayed: matchesPlayed,
      wins: wins,
      draws: draws,
      losses: losses,
      goals: goals,
      goalsConceded: goalsConceded,
      tournamentsJoined: tournamentsJoined,
      tournamentsFinished: tournamentsFinished,
      championCount: championCount,
      runnerUpCount: runnerUpCount,
      lastChampionAt: lastChampionAt,
      recentMatches: recentMatches,
      leagueHistory: leagueHistory,
      h2hSummary: h,
      updatedAt: updatedAt,
      schemaVersion: schemaVersion,
    );
  }
}
