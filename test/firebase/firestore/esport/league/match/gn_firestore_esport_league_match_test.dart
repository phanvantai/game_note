import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_firestore_esport_league_match.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/round_robin_scheduler.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_firestore_esport_league_stat.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late GNFirestore fs;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    fs = GNFirestore(fakeFirestore);
  });

  CollectionReference<Map<String, dynamic>> matchesCollection(String leagueId) {
    return fakeFirestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportMatch.collectionName);
  }

  CollectionReference<Map<String, dynamic>> statsCollection(String leagueId) {
    return fakeFirestore
        .collection(GNEsportLeague.collectionName)
        .doc(leagueId)
        .collection(GNEsportLeagueStat.collectionName);
  }

  Future<String> seedMatch({
    String leagueId = 'L1',
    String home = 'u1',
    String away = 'u2',
    String? phase,
    String? groupId,
    int? knockoutSlot,
    String? nextMatchId,
    bool finished = false,
    int homeScore = 0,
    int awayScore = 0,
    int? matchCost,
    Timestamp? updatedAt,
  }) async {
    final matchRef = await matchesCollection(leagueId).add({
      GNEsportMatch.fieldHomeTeamId: home,
      GNEsportMatch.fieldAwayTeamId: away,
      GNEsportMatch.fieldHomeScore: homeScore,
      GNEsportMatch.fieldAwayScore: awayScore,
      GNEsportMatch.fieldDate: Timestamp.fromDate(DateTime(2026, 5, 10)),
      GNEsportMatch.fieldIsFinished: finished,
      GNEsportMatch.fieldLeagueId: leagueId,
      GNEsportMatch.fieldPhase: ?phase,
      GNEsportMatch.fieldGroupId: ?groupId,
      GNEsportMatch.fieldKnockoutSlot: ?knockoutSlot,
      GNEsportMatch.fieldNextMatchId: ?nextMatchId,
      GNEsportMatch.fieldMatchCost: ?matchCost,
      GNEsportMatch.fieldUpdatedAt: ?updatedAt,
    });
    return matchRef.id;
  }

  Future<void> seedUser(String id, String name) {
    return fakeFirestore.collection(GNUser.collectionName).doc(id).set({
      GNUser.displayNameKey: name,
      GNUser.phoneNumberKey: null,
      GNUser.emailKey: '$id@example.com',
      GNUser.photoUrlKey: null,
      GNUser.roleKey: 'user',
      GNUser.fcmTokenKey: '',
    });
  }

  group('common helpers', () {
    test('ConcurrentMatchUpdateException mô tả match id', () {
      final error = ConcurrentMatchUpdateException('m1');

      expect(error.matchId, 'm1');
      expect(error.toString(), contains('m1'));
    });

    test('listenForMatchesUpdated emit danh sách match mới nhất', () async {
      final stream = fs.listenForMatchesUpdated('L1');

      await seedMatch(leagueId: 'L1', home: 'u1', away: 'u2');

      final matches = await stream.firstWhere((items) => items.isNotEmpty);
      expect(matches.single.homeTeamId, 'u1');
      expect(matches.single.awayTeamId, 'u2');
    });
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
          .map(
            (d) => {
              d.data()[GNEsportMatch.fieldHomeTeamId] as String,
              d.data()[GNEsportMatch.fieldAwayTeamId] as String,
            },
          )
          .toList();
      expect(
        pairs,
        containsAll([
          {'u1', 'u2'},
          {'u1', 'u3'},
          {'u2', 'u3'},
        ]),
      );
    });

    test(
      'khởi tạo league-wide stats (groupId=null) cho từng người chơi',
      () async {
        await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2', 'u3']);

        final stats = await fakeFirestore
            .collection(GNEsportLeague.collectionName)
            .doc('L1')
            .collection(GNEsportLeagueStat.collectionName)
            .get();

        expect(stats.docs, hasLength(3));
        final userIds = stats.docs.map(
          (d) => d.data()[GNEsportLeagueStat.fieldUserId],
        );
        expect(userIds, containsAll(['u1', 'u2', 'u3']));
        for (final doc in stats.docs) {
          final data = doc.data();
          expect(
            data[GNEsportLeagueStat.fieldGroupId],
            isNull,
            reason: 'league mode stats không có groupId',
          );
          expect(data[GNEsportLeagueStat.fieldMatchesPlayed], 0);
          expect(data[GNEsportLeagueStat.fieldGoals], 0);
          expect(data[GNEsportLeagueStat.fieldLeagueId], 'L1');
        }
      },
    );

    test(
      'không tạo duplicate stat khi tạo thêm round cho người chơi cũ',
      () async {
        await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2']);

        final statsCollection = fakeFirestore
            .collection(GNEsportLeague.collectionName)
            .doc('L1')
            .collection(GNEsportLeagueStat.collectionName);
        final firstStats = await statsCollection.get();
        final u1Stat = firstStats.docs.singleWhere(
          (d) => d.data()[GNEsportLeagueStat.fieldUserId] == 'u1',
        );
        await u1Stat.reference.update({
          GNEsportLeagueStat.fieldMatchesPlayed: 3,
          GNEsportLeagueStat.fieldWins: 2,
        });

        await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2']);

        final stats = await statsCollection.get();
        expect(stats.docs, hasLength(2));
        final userIds = stats.docs.map(
          (d) => d.data()[GNEsportLeagueStat.fieldUserId],
        );
        expect(userIds, unorderedEquals(['u1', 'u2']));
        final u1Rows = stats.docs
            .where((d) => d.data()[GNEsportLeagueStat.fieldUserId] == 'u1')
            .toList();
        expect(u1Rows, hasLength(1));
        expect(u1Rows.single.data()[GNEsportLeagueStat.fieldMatchesPlayed], 3);
        expect(u1Rows.single.data()[GNEsportLeagueStat.fieldWins], 2);
      },
    );

    test('bỏ qua userId trùng khi tạo round', () async {
      await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u1', 'u2']);

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

      expect(matches.docs, hasLength(1));
      expect(stats.docs, hasLength(2));
      final match = matches.docs.single.data();
      expect(
        {
          match[GNEsportMatch.fieldHomeTeamId] as String,
          match[GNEsportMatch.fieldAwayTeamId] as String,
        },
        {'u1', 'u2'},
      );
    });

    test(
      'không tạo match khi chỉ có 1 người chơi nhưng vẫn tạo stat',
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
      },
    );
  });

  group('generateRound - matchday', () {
    Future<List<int?>> matchdaysOf(String leagueId) async {
      final snapshot = await matchesCollection(leagueId).get();
      return snapshot.docs
          .map((d) => (d.data()[GNEsportMatch.fieldMatchday] as num?)?.toInt())
          .toList();
    }

    Future<int?> matchdayCounterOf(String leagueId) async {
      final snapshot = await fakeFirestore
          .collection(GNEsportLeague.collectionName)
          .doc(leagueId)
          .get();
      return (snapshot.data()?[GNEsportLeague.fieldMatchdayCount] as num?)
          ?.toInt();
    }

    test('gán số vòng cho từng trận của lượt', () async {
      await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2', 'u3']);

      expect(await matchdaysOf('L1'), unorderedEquals([1, 2, 3]));
    });

    test('4 người chơi tạo 3 vòng, mỗi vòng 2 trận', () async {
      await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2', 'u3', 'u4']);

      final matchdays = await matchdaysOf('L1');
      expect(matchdays, hasLength(6));
      expect(matchdays.where((m) => m == 1), hasLength(2));
      expect(matchdays.where((m) => m == 2), hasLength(2));
      expect(matchdays.where((m) => m == 3), hasLength(2));
    });

    test('ghi matchdayCount lên league document', () async {
      await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2', 'u3', 'u4']);

      expect(await matchdayCounterOf('L1'), 3);
    });

    test('lượt thứ hai tiếp số vòng thay vì bắt đầu lại', () async {
      await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2', 'u3', 'u4']);
      await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2', 'u3', 'u4']);

      final matchdays = await matchdaysOf('L1');
      expect(matchdays, hasLength(12));
      expect(matchdays.toSet(), {1, 2, 3, 4, 5, 6});
      expect(await matchdayCounterOf('L1'), 6);
    });

    test('lượt thứ hai đảo sân nhà so với lượt đầu', () async {
      await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2']);
      await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2']);

      final snapshot = await matchesCollection('L1').get();
      final homes = snapshot.docs
          .map((d) => d.data()[GNEsportMatch.fieldHomeTeamId] as String)
          .toList();

      expect(homes, unorderedEquals(['u1', 'u2']));
    });

    test('xoá hết trận của vòng cuối không giải phóng số vòng', () async {
      await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2']);

      final existing = await matchesCollection('L1').get();
      for (final doc in existing.docs) {
        await doc.reference.delete();
      }

      await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2']);

      expect(await matchdaysOf('L1'), [2]);
      expect(await matchdayCounterOf('L1'), 2);
    });

    test(
      'counter đi trước lịch đã đọc thì đảo chiều sân cho khớp nhịp lượt',
      () async {
        // Mô phỏng trạng thái mà một client khác đã cấp thêm lượt sau khi
        // client này đọc danh sách trận để tính chiều sân: counter = 1 nhưng
        // không còn trận nào để suy ra chiều. Lệch đúng một lượt trọn vẹn
        // nên lịch vừa dựng phải được đảo.
        await fakeFirestore
            .collection(GNEsportLeague.collectionName)
            .doc('L1')
            .set({GNEsportLeague.fieldMatchdayCount: 1});

        await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2']);

        final snapshot = await matchesCollection('L1').get();
        final match = snapshot.docs.single.data();
        expect(match[GNEsportMatch.fieldHomeTeamId], 'u2');
        expect(match[GNEsportMatch.fieldAwayTeamId], 'u1');
        expect(match[GNEsportMatch.fieldMatchday], 2);
      },
    );

    test('league cũ chưa có counter thì seed từ matchday lớn nhất', () async {
      await matchesCollection('L1').add({
        GNEsportMatch.fieldHomeTeamId: 'u1',
        GNEsportMatch.fieldAwayTeamId: 'u2',
        GNEsportMatch.fieldDate: Timestamp.fromDate(DateTime(2026, 5, 10)),
        GNEsportMatch.fieldIsFinished: false,
        GNEsportMatch.fieldLeagueId: 'L1',
        GNEsportMatch.fieldMatchday: 4,
      });

      await fs.generateRound(leagueId: 'L1', teamIds: ['u1', 'u2']);

      final matchdays = await matchdaysOf('L1');
      expect(matchdays, unorderedEquals([4, 5]));
      expect(await matchdayCounterOf('L1'), 5);
    });

    test('league cũ toàn trận không có matchday thì bắt đầu từ 1', () async {
      await seedMatch(leagueId: 'L1', home: 'u1', away: 'u2');

      await fs.generateRound(leagueId: 'L1', teamIds: ['u3', 'u4']);

      final matchdays = await matchdaysOf('L1');
      expect(matchdays, unorderedEquals([null, 1]));
    });

    test('trận knockout không được gán matchday', () async {
      await fs.generateCupBracket(
        leagueId: 'L1',
        seededTeamIds: ['u1', 'u2', 'u3', 'u4'],
      );

      expect(await matchdaysOf('L1'), everyElement(isNull));
    });

    test('trận vòng bảng không được gán matchday', () async {
      await fs.generateGroupRound(
        leagueId: 'L1',
        groupId: 'A',
        teamIds: ['u1', 'u2', 'u3'],
      );

      expect(await matchdaysOf('L1'), everyElement(isNull));
    });
  });

  group('generateRound - giới hạn ghi nguyên tử', () {
    List<String> teams(int count) => List.generate(count, (i) => 'u${i + 1}');

    test('32 người chơi vẫn tạo được lượt', () async {
      await fs.generateRound(leagueId: 'L1', teamIds: teams(32));

      final matches = await matchesCollection('L1').get();
      expect(matches.docs, hasLength(496));
    });

    test('33 người chơi ném RoundTooLargeException', () async {
      expect(
        () => fs.generateRound(leagueId: 'L1', teamIds: teams(33)),
        throwsA(isA<RoundTooLargeException>()),
      );
    });

    test('33 người chơi không ghi match hay stat nào', () async {
      await expectLater(
        fs.generateRound(leagueId: 'L1', teamIds: teams(33)),
        throwsA(isA<RoundTooLargeException>()),
      );

      final matches = await matchesCollection('L1').get();
      final stats = await statsCollection('L1').get();
      expect(matches.docs, isEmpty);
      expect(stats.docs, isEmpty);
    });

    test('RoundTooLargeException mô tả số người chơi và giới hạn', () {
      final error = RoundTooLargeException(
        participantCount: 33,
        maxParticipants: 32,
      );

      expect(error.participantCount, 33);
      expect(error.maxParticipants, 32);
      expect(error.toString(), contains('33'));
      expect(error.toString(), contains('32'));
    });
  });

  group('generateGroupRound', () {
    test('tạo group matches đúng groupId và không tạo stat mới', () async {
      await fs.generateGroupRound(
        leagueId: 'L1',
        groupId: 'A',
        teamIds: ['u1', 'u2', 'u3'],
      );

      final matches = await matchesCollection('L1').get();
      final stats = await statsCollection('L1').get();

      expect(matches.docs, hasLength(3));
      for (final doc in matches.docs) {
        final data = doc.data();
        expect(data[GNEsportMatch.fieldPhase], 'group');
        expect(data[GNEsportMatch.fieldGroupId], 'A');
      }
      expect(stats.docs, isEmpty);
    });
  });

  group('generateCupBracket', () {
    test('reject participant count không phải power-of-two', () async {
      expect(
        () => fs.generateCupBracket(leagueId: 'L1', seededTeamIds: ['u1']),
        throwsArgumentError,
      );
      expect(
        () => fs.generateCupBracket(
          leagueId: 'L1',
          seededTeamIds: ['u1', 'u2', 'u3'],
        ),
        throwsArgumentError,
      );
    });

    test('tạo bracket nhiều round với nextMatchId và slot trống', () async {
      await fs.generateCupBracket(
        leagueId: 'L1',
        seededTeamIds: ['u1', 'u2', 'u3', 'u4'],
      );

      final matches = await matchesCollection('L1').get();
      expect(matches.docs, hasLength(3));

      final byRound = <int, List<Map<String, dynamic>>>{};
      for (final doc in matches.docs) {
        final data = doc.data();
        final round = data[GNEsportMatch.fieldKnockoutRound] as int;
        byRound.putIfAbsent(round, () => []).add(data);
      }
      expect(byRound[0], hasLength(2));
      expect(byRound[1], hasLength(1));
      expect(
        byRound[0]!.map((m) => m[GNEsportMatch.fieldNextMatchId]).toSet(),
        hasLength(1),
      );
      expect(byRound[1]!.single[GNEsportMatch.fieldHomeTeamId], '');
      expect(byRound[1]!.single[GNEsportMatch.fieldAwayTeamId], '');
      expect(byRound[1]!.single[GNEsportMatch.fieldNextMatchId], isNull);
    });
  });

  group('generateFullTournament', () {
    test('reject knockout size không phải power-of-two', () async {
      expect(
        () => fs.generateFullTournament(
          leagueId: 'L1',
          groups: [
            ['u1', 'u2', 'u3'],
          ],
          advanceCount: 1,
        ),
        throwsArgumentError,
      );
    });

    test('tạo group stage, group stats và knockout không seed', () async {
      await fs.generateFullTournament(
        leagueId: 'L1',
        groups: [
          ['u1', 'u2'],
          ['u3', 'u4'],
        ],
        advanceCount: 1,
      );

      final matches = await matchesCollection('L1').get();
      final stats = await statsCollection('L1').get();

      expect(
        matches.docs.where(
          (d) => d.data()[GNEsportMatch.fieldPhase] == 'group',
        ),
        hasLength(2),
      );
      expect(
        matches.docs.where(
          (d) => d.data()[GNEsportMatch.fieldPhase] == 'knockout',
        ),
        hasLength(1),
      );
      expect(stats.docs, hasLength(4));
      expect(
        stats.docs.map((d) => d.data()[GNEsportLeagueStat.fieldGroupId]),
        containsAll(['A', 'B']),
      );
    });

    test('tạo full tournament với knockout seeding nhiều round', () async {
      await fs.generateFullTournament(
        leagueId: 'L1',
        groups: [
          ['u1', 'u2'],
          ['u3', 'u4'],
          ['u5', 'u6'],
          ['u7', 'u8'],
        ],
        advanceCount: 1,
        knockoutSeeding: ['u1', 'u3', 'u5', 'u7'],
      );

      final matches = await matchesCollection('L1').get();
      final knockout = matches.docs
          .map((d) => d.data())
          .where((d) => d[GNEsportMatch.fieldPhase] == 'knockout')
          .toList();
      expect(knockout, hasLength(3));
      expect(
        knockout.where((d) => d[GNEsportMatch.fieldKnockoutRound] == 0),
        hasLength(2),
      );
      expect(
        knockout.where((d) => d[GNEsportMatch.fieldKnockoutRound] == 1),
        hasLength(1),
      );
      expect(
        knockout
            .where((d) => d[GNEsportMatch.fieldKnockoutRound] == 0)
            .map((d) => d[GNEsportMatch.fieldHomeTeamId]),
        containsAll(['u1', 'u3']),
      );
    });
  });

  group('getMatches', () {
    test('trả về matches kèm user data, bỏ qua team id rỗng', () async {
      await seedUser('u1', 'Alice');
      await seedUser('u2', 'Bob');
      await seedMatch(leagueId: 'L1', home: 'u1', away: 'u2');
      await seedMatch(leagueId: 'L1', home: '', away: '');

      final matches = await fs.getMatches('L1');

      final played = matches.singleWhere((m) => m.homeTeamId == 'u1');
      expect(played.homeTeam?.displayName, 'Alice');
      expect(played.awayTeam?.displayName, 'Bob');
      final empty = matches.singleWhere((m) => m.homeTeamId.isEmpty);
      expect(empty.homeTeam, isNull);
      expect(empty.awayTeam, isNull);
    });
  });

  group('updateMatch — chỉ ghi match doc, không động vào stats', () {
    Future<String> seedMatch({
      required String leagueId,
      required String home,
      required String away,
      String? phase,
      String? groupId,
      int? knockoutSlot,
      String? nextMatchId,
      bool finished = false,
      int homeScore = 0,
      int awayScore = 0,
      int? matchCost,
      Timestamp? updatedAt,
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
            GNEsportMatch.fieldKnockoutSlot: ?knockoutSlot,
            GNEsportMatch.fieldNextMatchId: ?nextMatchId,
            GNEsportMatch.fieldMatchCost: ?matchCost,
            GNEsportMatch.fieldUpdatedAt: ?updatedAt,
          });
      return matchRef.id;
    }

    test('updateMatch ghi score nhưng KHÔNG đụng stat doc — '
        'kể cả khi stat chưa tồn tại', () async {
      // Repro: legacy league chưa có stat doc nào. updateMatch lean
      // không được throw "No stats found" — đó là việc của
      // applyMatchStatDelta về sau.
      final matchId = await seedMatch(leagueId: 'L1', home: 'u1', away: 'u2');

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
      expect(
        stats.docs,
        isEmpty,
        reason: 'updateMatch không được tự khởi tạo stat',
      );
    });

    test('updateMatch knockout: vẫn advance winner vào next bracket slot '
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
      expect(
        next.data()?[GNEsportMatch.fieldHomeTeamId],
        'u1',
        reason: 'winner phải advance vào slot tiếp theo',
      );
    });

    test('updateMatch throw khi match không tồn tại', () async {
      expect(
        () => fs.updateMatch(
          matchId: 'missing',
          leagueId: 'L1',
          homeScore: 1,
          awayScore: 0,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('updateMatch phát hiện concurrent update', () async {
      final storedUpdatedAt = Timestamp.fromDate(DateTime(2026, 5, 10));
      final staleUpdatedAt = Timestamp.fromDate(DateTime(2026, 5, 9));
      final matchId = await seedMatch(
        leagueId: 'L1',
        home: 'u1',
        away: 'u2',
        updatedAt: storedUpdatedAt,
      );

      expect(
        () => fs.updateMatch(
          matchId: matchId,
          leagueId: 'L1',
          homeScore: 1,
          awayScore: 0,
          expectedUpdatedAt: staleUpdatedAt,
        ),
        throwsA(isA<ConcurrentMatchUpdateException>()),
      );
    });

    test(
      'updateMatch cập nhật matchCost và advance away vào odd slot',
      () async {
        final nextId = await seedMatch(
          leagueId: 'L1',
          home: '',
          away: '',
          phase: 'knockout',
        );
        final matchId = await seedMatch(
          leagueId: 'L1',
          home: 'u1',
          away: 'u2',
          phase: 'knockout',
          knockoutSlot: 1,
          nextMatchId: nextId,
        );

        final result = await fs.updateMatch(
          matchId: matchId,
          leagueId: 'L1',
          homeScore: 1,
          awayScore: 4,
          matchCost: 75000,
        );

        expect(result.updated.matchCost, 75000);
        final next = await matchesCollection('L1').doc(nextId).get();
        expect(next.data()?[GNEsportMatch.fieldAwayTeamId], 'u2');
      },
    );
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

    test(
      'apply delta lần đầu (previous chưa finished → only apply new)',
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
      },
    );

    test(
      'apply delta khi sửa từ finished sang finished khác → undo + apply',
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
      },
    );

    test('knockout match → no-op, không đụng stats', () async {
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1');
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1');

      await fs.applyMatchStatDelta(
        previous: matchOf(finished: false, phase: 'knockout'),
        updated: matchOf(
          finished: true,
          phase: 'knockout',
          homeScore: 3,
          awayScore: 1,
        ),
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
        updated: matchOf(
          finished: true,
          home: '',
          away: '',
          homeScore: 1,
          awayScore: 0,
        ),
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
      },
    );

    test('stat doc thiếu trong group → throw kèm group id', () async {
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1', groupId: 'A');

      expect(
        () => fs.applyMatchStatDelta(
          previous: matchOf(finished: false, groupId: 'A'),
          updated: matchOf(
            finished: true,
            homeScore: 1,
            awayScore: 0,
            groupId: 'A',
          ),
        ),
        throwsA(
          predicate((e) => e is Exception && e.toString().contains('group A')),
        ),
      );
    });

    test('finished → unfinished undo toàn bộ delta', () async {
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1');
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1');
      await fs.applyMatchStatDelta(
        previous: matchOf(finished: false),
        updated: matchOf(finished: true, homeScore: 0, awayScore: 2),
      );

      await fs.applyMatchStatDelta(
        previous: matchOf(finished: true, homeScore: 0, awayScore: 2),
        updated: matchOf(finished: false),
      );

      final stats = await statsCollection('L1').get();
      for (final doc in stats.docs) {
        expect(doc.data()[GNEsportLeagueStat.fieldMatchesPlayed], 0);
        expect(doc.data()[GNEsportLeagueStat.fieldGoals], 0);
        expect(doc.data()[GNEsportLeagueStat.fieldLosses], 0);
      }
    });

    test('finished cùng tỉ số và cost-only change → no-op', () async {
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1');
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1');

      await fs.applyMatchStatDelta(
        previous: matchOf(finished: true, homeScore: 2, awayScore: 2),
        updated: matchOf(finished: true, homeScore: 2, awayScore: 2),
      );

      final stats = await statsCollection('L1').get();
      for (final doc in stats.docs) {
        expect(doc.data()[GNEsportLeagueStat.fieldMatchesPlayed], 0);
      }
    });

    test('group stat lookup chỉ dùng stat đúng group', () async {
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1', groupId: 'A');
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1', groupId: 'A');
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1', groupId: 'B');
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1', groupId: 'B');

      await fs.applyMatchStatDelta(
        previous: matchOf(finished: false, groupId: 'B'),
        updated: matchOf(
          finished: true,
          homeScore: 2,
          awayScore: 0,
          groupId: 'B',
        ),
      );

      final stats = await statsCollection('L1').get();
      final byGroup = {
        for (final d in stats.docs)
          '${d.data()[GNEsportLeagueStat.fieldUserId]}-${d.data()[GNEsportLeagueStat.fieldGroupId]}':
              d.data(),
      };
      expect(byGroup['u1-A']?[GNEsportLeagueStat.fieldMatchesPlayed], 0);
      expect(byGroup['u1-B']?[GNEsportLeagueStat.fieldMatchesPlayed], 1);
    });
  });

  group('createCustomMatch', () {
    test('ghi custom match với generated id và updatedAt', () async {
      await fs.createCustomMatch(
        GNEsportMatch(
          id: '',
          leagueId: 'L1',
          homeTeamId: 'u1',
          awayTeamId: 'u2',
          homeScore: 0,
          awayScore: 0,
          date: DateTime(2026, 5, 10),
          isFinished: false,
        ),
      );

      final matches = await matchesCollection('L1').get();
      expect(matches.docs, hasLength(1));
      final data = matches.docs.single.data();
      expect(data[GNEsportMatch.fieldHomeTeamId], 'u1');
      expect(data[GNEsportMatch.fieldUpdatedAt], isA<Timestamp>());
    });
  });

  group('deleteMatch', () {
    test('missing match vẫn return sau khi resolve stat refs', () async {
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1');
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1');

      await fs.deleteMatch(
        GNEsportMatch(
          id: 'missing',
          leagueId: 'L1',
          homeTeamId: 'u1',
          awayTeamId: 'u2',
          date: DateTime(2026, 5, 10),
          isFinished: false,
        ),
      );

      final stats = await statsCollection('L1').get();
      expect(stats.docs, hasLength(2));
    });

    test('unfinished match chỉ bị xoá, không đổi stats', () async {
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1');
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1');
      final matchId = await seedMatch(leagueId: 'L1', finished: false);

      await fs.deleteMatch(
        GNEsportMatch(
          id: matchId,
          leagueId: 'L1',
          homeTeamId: 'u1',
          awayTeamId: 'u2',
          date: DateTime(2026, 5, 10),
          isFinished: false,
        ),
      );

      final match = await matchesCollection('L1').doc(matchId).get();
      final stats = await statsCollection('L1').get();
      expect(match.exists, isFalse);
      for (final doc in stats.docs) {
        expect(doc.data()[GNEsportLeagueStat.fieldMatchesPlayed], 0);
      }
    });

    test('finished match bị xoá và stats được undo', () async {
      await fs.addLeagueStat(userId: 'u1', leagueId: 'L1');
      await fs.addLeagueStat(userId: 'u2', leagueId: 'L1');
      final matchId = await seedMatch(
        leagueId: 'L1',
        finished: true,
        homeScore: 3,
        awayScore: 1,
      );
      await fs.applyMatchStatDelta(
        previous: GNEsportMatch(
          id: matchId,
          leagueId: 'L1',
          homeTeamId: 'u1',
          awayTeamId: 'u2',
          date: DateTime(2026, 5, 10),
          isFinished: false,
        ),
        updated: GNEsportMatch(
          id: matchId,
          leagueId: 'L1',
          homeTeamId: 'u1',
          awayTeamId: 'u2',
          homeScore: 3,
          awayScore: 1,
          date: DateTime(2026, 5, 10),
          isFinished: true,
        ),
      );

      await fs.deleteMatch(
        GNEsportMatch(
          id: matchId,
          leagueId: 'L1',
          homeTeamId: 'u1',
          awayTeamId: 'u2',
          date: DateTime(2026, 5, 10),
          isFinished: true,
        ),
      );

      final match = await matchesCollection('L1').doc(matchId).get();
      final stats = await statsCollection('L1').get();
      final byUser = {
        for (final d in stats.docs)
          d.data()[GNEsportLeagueStat.fieldUserId] as String: d.data(),
      };
      expect(match.exists, isFalse);
      expect(byUser['u1']?[GNEsportLeagueStat.fieldMatchesPlayed], 0);
      expect(byUser['u1']?[GNEsportLeagueStat.fieldWins], 0);
      expect(byUser['u2']?[GNEsportLeagueStat.fieldLosses], 0);
    });
  });
}
