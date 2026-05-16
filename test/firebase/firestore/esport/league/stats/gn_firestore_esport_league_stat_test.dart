import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
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

  Future<void> seedLeague({
    required String id,
    required List<String> participants,
    TournamentMode mode = TournamentMode.league,
  }) async {
    await fakeFirestore
        .collection(GNEsportLeague.collectionName)
        .doc(id)
        .set({
      GNEsportLeague.fieldOwnerId: 'owner',
      GNEsportLeague.fieldGroupId: 'G1',
      GNEsportLeague.fieldName: 'L',
      GNEsportLeague.fieldStartDate: Timestamp.fromDate(DateTime(2026, 5)),
      GNEsportLeague.fieldIsActive: true,
      GNEsportLeague.fieldDescription: '',
      GNEsportLeague.fieldParticipants: participants,
      GNEsportLeague.fieldMode: mode.value,
    });
  }

  Future<void> seedMatch({
    required String leagueId,
    required String home,
    required String away,
    required int hs,
    required int as_,
    bool finished = true,
  }) async {
    await fakeFirestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportMatch.collectionName)
        .add({
      GNEsportMatch.fieldHomeTeamId: home,
      GNEsportMatch.fieldAwayTeamId: away,
      GNEsportMatch.fieldHomeScore: hs,
      GNEsportMatch.fieldAwayScore: as_,
      GNEsportMatch.fieldDate: Timestamp.fromDate(DateTime(2026, 5, 10)),
      GNEsportMatch.fieldIsFinished: finished,
      GNEsportMatch.fieldLeagueId: leagueId,
    });
  }

  group('recomputeLeagueStats — delete và tái tạo từ đầu', () {
    test('giải league cũ không có stat doc nào → backfill 1 stat/người chơi',
        () async {
      await seedLeague(id: 'L1', participants: ['u1', 'u2', 'u3']);

      await fs.recomputeLeagueStats('L1');

      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName)
          .get();
      expect(stats.docs, hasLength(3));
      final byUser = {
        for (final d in stats.docs)
          d.data()[GNEsportLeagueStat.fieldUserId] as String: d.data(),
      };
      for (final id in ['u1', 'u2', 'u3']) {
        expect(byUser[id]?[GNEsportLeagueStat.fieldGroupId], isNull);
        expect(byUser[id]?[GNEsportLeagueStat.fieldMatchesPlayed], 0);
      }
    });

    test(
        'backfill xong recompute luôn từ finished matches '
        '(legacy league có matches đã nhập tỉ số thủ công)', () async {
      await seedLeague(id: 'L1', participants: ['u1', 'u2']);
      // Match được seed như thể đã được sửa data thủ công — không qua flow
      // updateMatch (nó sẽ throw khi không có stat).
      await seedMatch(leagueId: 'L1', home: 'u1', away: 'u2', hs: 3, as_: 1);

      await fs.recomputeLeagueStats('L1');

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
      expect(byUser['u1']?[GNEsportLeagueStat.fieldGoalsConceded], 1);
      expect(byUser['u1']?[GNEsportLeagueStat.fieldWins], 1);
      expect(byUser['u2']?[GNEsportLeagueStat.fieldLosses], 1);
    });

    test('không tạo thêm stat khi mọi participant đã có stat doc', () async {
      await seedLeague(id: 'L1', participants: ['u1', 'u2']);
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1');
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1');

      await fs.recomputeLeagueStats('L1');

      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName)
          .get();
      expect(stats.docs, hasLength(2));
    });

    test(
        'full mode: participant đã có per-group stats → không tạo thêm '
        'stat groupId=null', () async {
      await seedLeague(
        id: 'L1',
        participants: ['u1', 'u2'],
        mode: TournamentMode.full,
      );
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1', groupId: 'A');
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1', groupId: 'A');

      await fs.recomputeLeagueStats('L1');

      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName)
          .get();
      expect(stats.docs, hasLength(2));
      for (final doc in stats.docs) {
        expect(doc.data()[GNEsportLeagueStat.fieldGroupId], 'A');
      }
    });

    test('league doc không tồn tại → không backfill, không lỗi', () async {
      await fs.recomputeLeagueStats('missing');

      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('missing')
          .collection(GNEsportLeagueStat.collectionName)
          .get();
      expect(stats.docs, isEmpty);
    });

    test('user có nhiều stat doc bị duplicate → bị clean về đúng 1 row',
        () async {
      // Repro bug user gặp: legacy data có 2+ stat doc cho cùng 1 user.
      await seedLeague(id: 'L1', participants: ['u1', 'u2']);
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1');
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1'); // dup
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1');

      await fs.recomputeLeagueStats('L1');

      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName)
          .get();
      expect(stats.docs, hasLength(2),
          reason: 'mỗi user chỉ còn đúng 1 stat row');
      final userIds = stats.docs
          .map((d) => d.data()[GNEsportLeagueStat.fieldUserId])
          .toList();
      expect(userIds.toSet(), {'u1', 'u2'});
    });

    test('orphan user trong match (không có trong participants) → vẫn có stat',
        () async {
      await seedLeague(id: 'L1', participants: ['u1', 'u2']);
      await seedMatch(
          leagueId: 'L1', home: 'u1', away: 'u3', hs: 0, as_: 0,
          finished: false);

      await fs.recomputeLeagueStats('L1');

      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName)
          .get();
      expect(
        stats.docs
            .map((d) => d.data()[GNEsportLeagueStat.fieldUserId])
            .toSet(),
        {'u1', 'u2', 'u3'},
      );
    });

    test('full mode: tái dựng per-group stats từ group matches', () async {
      await seedLeague(
        id: 'L1',
        participants: ['u1', 'u2', 'u3', 'u4'],
        mode: TournamentMode.full,
      );
      // Group A: u1, u2; Group B: u3, u4
      await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportMatch.collectionName)
          .add({
        GNEsportMatch.fieldHomeTeamId: 'u1',
        GNEsportMatch.fieldAwayTeamId: 'u2',
        GNEsportMatch.fieldHomeScore: 2,
        GNEsportMatch.fieldAwayScore: 1,
        GNEsportMatch.fieldDate: Timestamp.fromDate(DateTime(2026, 5, 10)),
        GNEsportMatch.fieldIsFinished: true,
        GNEsportMatch.fieldLeagueId: 'L1',
        GNEsportMatch.fieldPhase: 'group',
        GNEsportMatch.fieldGroupId: 'A',
      });
      await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportMatch.collectionName)
          .add({
        GNEsportMatch.fieldHomeTeamId: 'u3',
        GNEsportMatch.fieldAwayTeamId: 'u4',
        GNEsportMatch.fieldHomeScore: 0,
        GNEsportMatch.fieldAwayScore: 0,
        GNEsportMatch.fieldDate: Timestamp.fromDate(DateTime(2026, 5, 10)),
        GNEsportMatch.fieldIsFinished: true,
        GNEsportMatch.fieldLeagueId: 'L1',
        GNEsportMatch.fieldPhase: 'group',
        GNEsportMatch.fieldGroupId: 'B',
      });

      await fs.recomputeLeagueStats('L1');

      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName)
          .get();
      expect(stats.docs, hasLength(4));
      final byUserGroup = {
        for (final d in stats.docs)
          '${d.data()[GNEsportLeagueStat.fieldUserId]}/${d.data()[GNEsportLeagueStat.fieldGroupId]}':
              d.data(),
      };
      expect(byUserGroup.keys.toSet(), {'u1/A', 'u2/A', 'u3/B', 'u4/B'});
      expect(byUserGroup['u1/A']?[GNEsportLeagueStat.fieldGoals], 2);
      expect(byUserGroup['u1/A']?[GNEsportLeagueStat.fieldWins], 1);
      expect(byUserGroup['u3/B']?[GNEsportLeagueStat.fieldDraws], 1);
    });

    test('knockout match không tính vào stats', () async {
      await seedLeague(id: 'L1', participants: ['u1', 'u2']);
      await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportMatch.collectionName)
          .add({
        GNEsportMatch.fieldHomeTeamId: 'u1',
        GNEsportMatch.fieldAwayTeamId: 'u2',
        GNEsportMatch.fieldHomeScore: 5,
        GNEsportMatch.fieldAwayScore: 0,
        GNEsportMatch.fieldDate: Timestamp.fromDate(DateTime(2026, 5, 10)),
        GNEsportMatch.fieldIsFinished: true,
        GNEsportMatch.fieldLeagueId: 'L1',
        GNEsportMatch.fieldPhase: 'knockout',
      });

      await fs.recomputeLeagueStats('L1');

      final stats = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc('L1')
          .collection(GNEsportLeagueStat.collectionName)
          .get();
      for (final doc in stats.docs) {
        expect(doc.data()[GNEsportLeagueStat.fieldMatchesPlayed], 0,
            reason: 'knockout không track stats');
      }
    });
  });
}
