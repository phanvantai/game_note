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

  group('updateMatch — stat lookup khi groupId field bị omit', () {
    // Repro chính xác bug user gặp: addLeagueStat ghi doc thiếu field
    // groupId (toMap bỏ field khi null). Nếu _statRefForUser query bằng
    // `where(isNull: true)` thì sẽ không match những doc này → throw
    // "No stats found".
    Future<String> seedMatchAndStats({
      required String leagueId,
      required String home,
      required String away,
    }) async {
      await fs.addLeagueStat(userId: home, leagueId: leagueId);
      await fs.addLeagueStat(userId: away, leagueId: leagueId);
      final matchRef = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc(leagueId)
          .collection(GNEsportMatch.collectionName)
          .add({
        GNEsportMatch.fieldHomeTeamId: home,
        GNEsportMatch.fieldAwayTeamId: away,
        GNEsportMatch.fieldHomeScore: 0,
        GNEsportMatch.fieldAwayScore: 0,
        GNEsportMatch.fieldDate: Timestamp.fromDate(DateTime(2026, 5, 10)),
        GNEsportMatch.fieldIsFinished: false,
        GNEsportMatch.fieldLeagueId: leagueId,
      });
      return matchRef.id;
    }

    test('league mode: nhập tỉ số thành công và cập nhật stats', () async {
      final matchId = await seedMatchAndStats(
        leagueId: 'L1',
        home: 'u1',
        away: 'u2',
      );

      await fs.updateMatch(
        matchId: matchId,
        leagueId: 'L1',
        homeScore: 3,
        awayScore: 1,
      );

      // Stats được tìm thấy và update — pre-fix sẽ throw "No stats found".
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
      expect(byUser['u2']?[GNEsportLeagueStat.fieldGoalsConceded], 3);
      expect(byUser['u2']?[GNEsportLeagueStat.fieldLosses], 1);
    });

    test(
        'full mode: groupId field có giá trị → vẫn tìm đúng stat của group',
        () async {
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1', groupId: 'A');
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1', groupId: 'A');
      // Stat của cùng user nhưng ở group khác — không được nhầm.
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1', groupId: 'B');

      final matchRef = await fakeFirestore
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
        GNEsportMatch.fieldPhase: 'group',
        GNEsportMatch.fieldGroupId: 'A',
      });

      await fs.updateMatch(
        matchId: matchRef.id,
        leagueId: 'L1',
        homeScore: 2,
        awayScore: 2,
      );

      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName)
          .get();
      final groupAU1 = stats.docs.firstWhere((d) =>
          d.data()[GNEsportLeagueStat.fieldUserId] == 'u1' &&
          d.data()[GNEsportLeagueStat.fieldGroupId] == 'A');
      final groupBU1 = stats.docs.firstWhere((d) =>
          d.data()[GNEsportLeagueStat.fieldUserId] == 'u1' &&
          d.data()[GNEsportLeagueStat.fieldGroupId] == 'B');
      expect(groupAU1.data()[GNEsportLeagueStat.fieldDraws], 1);
      expect(groupBU1.data()[GNEsportLeagueStat.fieldDraws], 0,
          reason: 'không được update stat của group khác');
    });
  });
}
