import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_firestore_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GNFirestore fs;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fs = GNFirestore(fakeFirestore);
  });

  group('generateRound', () {
    test('tạo round-robin matches cho mỗi cặp người chơi', () async {
      await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2', 'u3']);

      final matches = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportMatch.collectionName)
          .get();

      expect(matches.docs, hasLength(3));
      final pairs = matches.docs
          .map((d) => {
                d.data()[GNEsportMatch.fieldHomeTeamId] as String,
                d.data()[GNEsportMatch.fieldAwayTeamId] as String,
              })
          .toList();
      expect(pairs, containsAll([
        {'u1', 'u2'},
        {'u1', 'u3'},
        {'u2', 'u3'},
      ]));
    });

    test('khởi tạo league-wide stats (groupId=null) cho từng người chơi',
        () async {
      await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2', 'u3']);

      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName)
          .get();

      expect(stats.docs, hasLength(3));
      final userIds =
          stats.docs.map((d) => d.data()[GNEsportLeagueStat.fieldUserId]);
      expect(userIds, containsAll(['u1', 'u2', 'u3']));
      for (final doc in stats.docs) {
        final data = doc.data();
        expect(data[GNEsportLeagueStat.fieldGroupId], isNull,
            reason: 'league mode stats không có groupId');
        expect(data[GNEsportLeagueStat.fieldMatchesPlayed], 0);
        expect(data[GNEsportLeagueStat.fieldGoals], 0);
        expect(data[GNEsportLeagueStat.fieldLeagueId], 'L1');
      }
    });

    test('không tạo match khi chỉ có 1 người chơi nhưng vẫn tạo stat',
        () async {
      await fs.generateRound(leagueId: 'L1', teamIds: ['u1']);

      final matches = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportMatch.collectionName)
          .get();
      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName)
          .get();

      expect(matches.docs, isEmpty);
      expect(stats.docs, hasLength(1));
    });
  });

  group('updateMatch — chỉ ghi match doc, không động vào stats', () {
    Future<String> seedMatch({
      required String leagueId,
      required String home,
      required String away,
      String? phase,
      String? groupId,
      bool finished = false,
      int homeScore = 0,
      int awayScore = 0,
    }) async {
      final matchRef = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc(leagueId)
          .collection(GNEsportMatch.collectionName)
          .add({
        GNEsportMatch.fieldHomeTeamId: home,
        GNEsportMatch.fieldAwayTeamId: away,
        GNEsportMatch.fieldHomeScore: homeScore,
        GNEsportMatch.fieldAwayScore: awayScore,
        GNEsportMatch.fieldDate: Timestamp.fromDate(DateTime(2026, 5, 10)),
        GNEsportMatch.fieldIsFinished: finished,
        GNEsportMatch.fieldLeagueId: leagueId,
        GNEsportMatch.fieldPhase: ?phase,
        GNEsportMatch.fieldGroupId: ?groupId,
      });
      return matchRef.id;
    }

    test(
        'updateMatch ghi score nhưng KHÔNG đụng stat doc — '
        'kể cả khi stat chưa tồn tại', () async {
      // Repro: legacy league chưa có stat doc nào. updateMatch lean
      // không được throw "No stats found" — đó là việc của
      // applyMatchStatDelta về sau.
      final matchId =
          await seedMatch(leagueId: 'L1', home: 'u1', away: 'u2');

      final result = await fs.updateMatch(
        matchId: matchId,
        leagueId: 'L1',
        homeScore: 3,
        awayScore: 1,
      );

      // Match doc đã update.
      final matchDoc = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportMatch.collectionName)
          .doc(matchId)
          .get();
      expect(matchDoc.data()?[GNEsportMatch.fieldHomeScore], 3);
      expect(matchDoc.data()?[GNEsportMatch.fieldAwayScore], 1);
      expect(matchDoc.data()?[GNEsportMatch.fieldIsFinished], true);

      // previous/updated trả về để caller tự apply delta.
      expect(result.previous.homeScore, 0);
      expect(result.previous.isFinished, false);
      expect(result.updated.homeScore, 3);
      expect(result.updated.isFinished, true);

      // Stat collection rỗng — updateMatch không tự tạo.
      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName)
          .get();
      expect(stats.docs, isEmpty,
          reason: 'updateMatch không được tự khởi tạo stat');
    });

    test(
        'updateMatch knockout: vẫn advance winner vào next bracket slot '
        'atomic với score', () async {
      final nextId = await seedMatch(
        leagueId: 'L1',
        home: '',
        away: '',
        phase: 'knockout',
      );
      final firstMatchRef = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportMatch.collectionName)
          .add({
        GNEsportMatch.fieldHomeTeamId: 'u1',
        GNEsportMatch.fieldAwayTeamId: 'u2',
        GNEsportMatch.fieldHomeScore: 0,
        GNEsportMatch.fieldAwayScore: 0,
        GNEsportMatch.fieldDate: Timestamp.fromDate(DateTime(2026, 5, 10)),
        GNEsportMatch.fieldIsFinished: false,
        GNEsportMatch.fieldLeagueId: 'L1',
        GNEsportMatch.fieldPhase: 'knockout',
        GNEsportMatch.fieldKnockoutSlot: 0,
        GNEsportMatch.fieldNextMatchId: nextId,
      });

      await fs.updateMatch(
        matchId: firstMatchRef.id,
        leagueId: 'L1',
        homeScore: 3,
        awayScore: 1,
      );

      final next = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportMatch.collectionName)
          .doc(nextId)
          .get();
      expect(next.data()?[GNEsportMatch.fieldHomeTeamId], 'u1',
          reason: 'winner phải advance vào slot tiếp theo');
    });
  });

  group('applyMatchStatDelta', () {
    GNEsportMatch matchOf({
      required bool finished,
      int? homeScore,
      int? awayScore,
      String home = 'u1',
      String away = 'u2',
      String? phase,
      String? groupId,
    }) {
      return GNEsportMatch(
        id: 'm1',
        leagueId: 'L1',
        homeTeamId: home,
        awayTeamId: away,
        homeScore: homeScore,
        awayScore: awayScore,
        date: DateTime(2026, 5, 10),
        isFinished: finished,
        phase: phase,
        groupId: groupId,
      );
    }

    test('apply delta lần đầu (previous chưa finished → only apply new)',
        () async {
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1');
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1');

      await fs.applyMatchStatDelta(
        previous: matchOf(finished: false),
        updated: matchOf(finished: true, homeScore: 3, awayScore: 1),
      );

      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName)
          .get();
      final byUser = {
        for (final d in stats.docs)
          d.data()[GNEsportLeagueStat.fieldUserId] as String: d.data(),
      };
      expect(byUser['u1']?[GNEsportLeagueStat.fieldGoals], 3);
      expect(byUser['u1']?[GNEsportLeagueStat.fieldWins], 1);
      expect(byUser['u2']?[GNEsportLeagueStat.fieldLosses], 1);
    });

    test('apply delta khi sửa từ finished sang finished khác → undo + apply',
        () async {
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1');
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1');
      // Trận trước: 3-1 (u1 win)
      await fs.applyMatchStatDelta(
        previous: matchOf(finished: false),
        updated: matchOf(finished: true, homeScore: 3, awayScore: 1),
      );
      // Đổi tỉ số sang 1-1 (hòa)
      await fs.applyMatchStatDelta(
        previous: matchOf(finished: true, homeScore: 3, awayScore: 1),
        updated: matchOf(finished: true, homeScore: 1, awayScore: 1),
      );

      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName)
          .get();
      final byUser = {
        for (final d in stats.docs)
          d.data()[GNEsportLeagueStat.fieldUserId] as String: d.data(),
      };
      expect(byUser['u1']?[GNEsportLeagueStat.fieldGoals], 1);
      expect(byUser['u1']?[GNEsportLeagueStat.fieldWins], 0);
      expect(byUser['u1']?[GNEsportLeagueStat.fieldDraws], 1);
      expect(byUser['u2']?[GNEsportLeagueStat.fieldDraws], 1);
    });

    test('knockout match → no-op, không đụng stats', () async {
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1');
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1');

      await fs.applyMatchStatDelta(
        previous: matchOf(finished: false, phase: 'knockout'),
        updated: matchOf(
            finished: true, phase: 'knockout', homeScore: 3, awayScore: 1),
      );

      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName)
          .get();
      // Stats vẫn ở mức zero — knockout không track.
      for (final doc in stats.docs) {
        expect(doc.data()[GNEsportLeagueStat.fieldMatchesPlayed], 0);
      }
    });

    test('homeTeamId rỗng (TBD bracket slot) → no-op', () async {
      // Không cần seed stat — phải bail out trước khi resolve refs.
      await fs.applyMatchStatDelta(
        previous: matchOf(finished: false, home: '', away: ''),
        updated:
            matchOf(finished: true, home: '', away: '', homeScore: 1, awayScore: 0),
      );
      // Không throw là pass.
    });

    test(
        'stat doc thiếu cho user → throw (bloc swallow, manual sync cứu)',
        () async {
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1');
      // u2 không có stat doc

      expect(
        () => fs.applyMatchStatDelta(
          previous: matchOf(finished: false),
          updated: matchOf(finished: true, homeScore: 1, awayScore: 0),
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
