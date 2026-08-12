import 'dart:async';

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

final class _ControlledTransactionFirestore extends FakeFirebaseFirestore {
  Future<void> Function()? beforeNextTransaction;
  Future<void> _transactionTail = Future<void>.value();

  @override
  Future<T> runTransaction<T>(
    TransactionHandler<T> transactionHandler, {
    Duration timeout = const Duration(seconds: 30),
    int maxAttempts = 5,
  }) {
    final completer = Completer<T>();
    _transactionTail = _transactionTail.then((_) async {
      try {
        final beforeTransaction = beforeNextTransaction;
        beforeNextTransaction = null;
        if (beforeTransaction != null) await beforeTransaction();

        final result = await super.runTransaction(
          transactionHandler,
          timeout: timeout,
          maxAttempts: maxAttempts,
        );
        // fake_cloud_firestore does not await the dummy transaction's writes.
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        completer.complete(result);
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }
}

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
    int? costPerGoal,
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
      GNEsportMatch.fieldCostPerGoal: ?costPerGoal,
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

  group('updateMatchAtomically', () {
    Future<DocumentReference<Map<String, dynamic>>> seedStat({
      required String id,
      required String leagueId,
      required String userId,
      String? groupId,
      int matchesPlayed = 0,
      int goals = 0,
      int goalsConceded = 0,
      int wins = 0,
      int draws = 0,
      int losses = 0,
    }) async {
      final ref = statsCollection(leagueId).doc(id);
      await ref.set({
        GNEsportLeagueStat.fieldUserId: userId,
        GNEsportLeagueStat.fieldLeagueId: leagueId,
        GNEsportLeagueStat.fieldMatchesPlayed: matchesPlayed,
        GNEsportLeagueStat.fieldGoals: goals,
        GNEsportLeagueStat.fieldGoalsConceded: goalsConceded,
        GNEsportLeagueStat.fieldWins: wins,
        GNEsportLeagueStat.fieldDraws: draws,
        GNEsportLeagueStat.fieldLosses: losses,
        GNEsportLeagueStat.fieldGroupId: ?groupId,
      });
      return ref;
    }

    Future<Map<String, dynamic>> statFor(
      String leagueId,
      String userId, {
      String? groupId,
    }) async {
      final snapshot = await statsCollection(
        leagueId,
      ).where(GNEsportLeagueStat.fieldUserId, isEqualTo: userId).get();
      return snapshot.docs
          .singleWhere(
            (doc) =>
                (doc.data()[GNEsportLeagueStat.fieldGroupId] as String?) ==
                groupId,
          )
          .data();
    }

    Future<Object?> capture(Future<void> operation) async {
      try {
        await operation;
        return null;
      } catch (error) {
        return error;
      }
    }

    test(
      'league first result writes match, random-ID stats, and costPerGoal',
      () async {
        final matchId = await seedMatch(leagueId: 'atomic-1');
        await seedStat(
          id: 'random-home-stat-7',
          leagueId: 'atomic-1',
          userId: 'u1',
        );
        await seedStat(
          id: 'random-away-stat-9',
          leagueId: 'atomic-1',
          userId: 'u2',
        );

        await fs.updateMatchAtomically(
          matchId: matchId,
          leagueId: 'atomic-1',
          homeScore: 4,
          awayScore: 2,
          matchCost: 90000,
          costPerGoal: 12000,
        );

        final match = (await matchesCollection(
          'atomic-1',
        ).doc(matchId).get()).data()!;
        expect(match[GNEsportMatch.fieldHomeScore], 4);
        expect(match[GNEsportMatch.fieldAwayScore], 2);
        expect(match[GNEsportMatch.fieldIsFinished], true);
        expect(match[GNEsportMatch.fieldMatchCost], 90000);
        expect(match[GNEsportMatch.fieldCostPerGoal], 12000);
        expect(match[GNEsportMatch.fieldUpdatedAt], isA<Timestamp>());

        final statDocs = await statsCollection('atomic-1').get();
        expect(
          statDocs.docs.map((doc) => doc.id),
          unorderedEquals(['random-home-stat-7', 'random-away-stat-9']),
        );
        expect(await statFor('atomic-1', 'u1'), {
          GNEsportLeagueStat.fieldUserId: 'u1',
          GNEsportLeagueStat.fieldLeagueId: 'atomic-1',
          GNEsportLeagueStat.fieldMatchesPlayed: 1,
          GNEsportLeagueStat.fieldGoals: 4,
          GNEsportLeagueStat.fieldGoalsConceded: 2,
          GNEsportLeagueStat.fieldWins: 1,
          GNEsportLeagueStat.fieldDraws: 0,
          GNEsportLeagueStat.fieldLosses: 0,
        });
        expect(await statFor('atomic-1', 'u2'), {
          GNEsportLeagueStat.fieldUserId: 'u2',
          GNEsportLeagueStat.fieldLeagueId: 'atomic-1',
          GNEsportLeagueStat.fieldMatchesPlayed: 1,
          GNEsportLeagueStat.fieldGoals: 2,
          GNEsportLeagueStat.fieldGoalsConceded: 4,
          GNEsportLeagueStat.fieldWins: 0,
          GNEsportLeagueStat.fieldDraws: 0,
          GNEsportLeagueStat.fieldLosses: 1,
        });
      },
    );

    test(
      'finished edit undoes old result and applies new result once',
      () async {
        final version = Timestamp.fromDate(DateTime(2026, 6, 1));
        final matchId = await seedMatch(
          leagueId: 'atomic-2',
          finished: true,
          homeScore: 3,
          awayScore: 1,
          updatedAt: version,
        );
        await seedStat(
          id: 'old-home',
          leagueId: 'atomic-2',
          userId: 'u1',
          matchesPlayed: 1,
          goals: 3,
          goalsConceded: 1,
          wins: 1,
        );
        await seedStat(
          id: 'old-away',
          leagueId: 'atomic-2',
          userId: 'u2',
          matchesPlayed: 1,
          goals: 1,
          goalsConceded: 3,
          losses: 1,
        );

        await fs.updateMatchAtomically(
          matchId: matchId,
          leagueId: 'atomic-2',
          homeScore: 1,
          awayScore: 1,
          expectedUpdatedAt: version,
        );

        expect(await statFor('atomic-2', 'u1'), {
          GNEsportLeagueStat.fieldUserId: 'u1',
          GNEsportLeagueStat.fieldLeagueId: 'atomic-2',
          GNEsportLeagueStat.fieldMatchesPlayed: 1,
          GNEsportLeagueStat.fieldGoals: 1,
          GNEsportLeagueStat.fieldGoalsConceded: 1,
          GNEsportLeagueStat.fieldWins: 0,
          GNEsportLeagueStat.fieldDraws: 1,
          GNEsportLeagueStat.fieldLosses: 0,
        });
        expect(await statFor('atomic-2', 'u2'), {
          GNEsportLeagueStat.fieldUserId: 'u2',
          GNEsportLeagueStat.fieldLeagueId: 'atomic-2',
          GNEsportLeagueStat.fieldMatchesPlayed: 1,
          GNEsportLeagueStat.fieldGoals: 1,
          GNEsportLeagueStat.fieldGoalsConceded: 1,
          GNEsportLeagueStat.fieldWins: 0,
          GNEsportLeagueStat.fieldDraws: 1,
          GNEsportLeagueStat.fieldLosses: 0,
        });
      },
    );

    test(
      'cost-only update preserves finished score and stat contribution',
      () async {
        final version = Timestamp.fromDate(DateTime(2026, 6, 2));
        final matchId = await seedMatch(
          leagueId: 'atomic-cost-only',
          finished: true,
          homeScore: 3,
          awayScore: 1,
          matchCost: 50000,
          costPerGoal: 4000,
          updatedAt: version,
        );
        final homeStatRef = await seedStat(
          id: 'cost-only-home-random',
          leagueId: 'atomic-cost-only',
          userId: 'u1',
          matchesPlayed: 1,
          goals: 3,
          goalsConceded: 1,
          wins: 1,
        );
        final awayStatRef = await seedStat(
          id: 'cost-only-away-random',
          leagueId: 'atomic-cost-only',
          userId: 'u2',
          matchesPlayed: 1,
          goals: 1,
          goalsConceded: 3,
          losses: 1,
        );
        final homeStatBefore = (await homeStatRef.get()).data();
        final awayStatBefore = (await awayStatRef.get()).data();

        await fs.updateMatchAtomically(
          matchId: matchId,
          leagueId: 'atomic-cost-only',
          matchCost: 90000,
          costPerGoal: 12000,
          expectedUpdatedAt: version,
        );

        final match = (await matchesCollection(
          'atomic-cost-only',
        ).doc(matchId).get()).data()!;
        expect(match[GNEsportMatch.fieldHomeScore], 3);
        expect(match[GNEsportMatch.fieldAwayScore], 1);
        expect(match[GNEsportMatch.fieldIsFinished], true);
        expect(match[GNEsportMatch.fieldMatchCost], 90000);
        expect(match[GNEsportMatch.fieldCostPerGoal], 12000);
        expect(match[GNEsportMatch.fieldUpdatedAt], isA<Timestamp>());
        expect(match[GNEsportMatch.fieldUpdatedAt], isNot(version));
        expect((await homeStatRef.get()).data(), homeStatBefore);
        expect((await awayStatRef.get()).data(), awayStatBefore);
      },
    );

    test(
      'participant changed after stat lookup aborts score and stat writes',
      () async {
        final controlled = _ControlledTransactionFirestore();
        fakeFirestore = controlled;
        fs = GNFirestore(controlled);
        final version = Timestamp.fromDate(DateTime(2026, 6, 3));
        final matchId = await seedMatch(
          leagueId: 'atomic-identity-race',
          matchCost: 5000,
          updatedAt: version,
        );
        final homeStatRef = await seedStat(
          id: 'identity-home-random',
          leagueId: 'atomic-identity-race',
          userId: 'u1',
        );
        final awayStatRef = await seedStat(
          id: 'identity-away-random',
          leagueId: 'atomic-identity-race',
          userId: 'u2',
        );
        final homeStatBefore = (await homeStatRef.get()).data();
        final awayStatBefore = (await awayStatRef.get()).data();
        controlled.beforeNextTransaction = () {
          return matchesCollection(
            'atomic-identity-race',
          ).doc(matchId).update({GNEsportMatch.fieldHomeTeamId: 'u3'});
        };

        await expectLater(
          fs.updateMatchAtomically(
            matchId: matchId,
            leagueId: 'atomic-identity-race',
            homeScore: 2,
            awayScore: 0,
            matchCost: 80000,
            expectedUpdatedAt: version,
          ),
          throwsA(isA<Exception>()),
        );

        final match = (await matchesCollection(
          'atomic-identity-race',
        ).doc(matchId).get()).data()!;
        expect(match[GNEsportMatch.fieldHomeTeamId], 'u3');
        expect(match[GNEsportMatch.fieldAwayTeamId], 'u2');
        expect(match[GNEsportMatch.fieldHomeScore], 0);
        expect(match[GNEsportMatch.fieldAwayScore], 0);
        expect(match[GNEsportMatch.fieldIsFinished], false);
        expect(match[GNEsportMatch.fieldMatchCost], 5000);
        expect(match[GNEsportMatch.fieldUpdatedAt], version);
        expect((await homeStatRef.get()).data(), homeStatBefore);
        expect((await awayStatRef.get()).data(), awayStatBefore);
      },
    );

    test('group result changes only stats with the matching groupId', () async {
      final matchId = await seedMatch(
        leagueId: 'atomic-3',
        phase: 'group',
        groupId: 'B',
      );
      for (final groupId in ['A', 'B']) {
        await seedStat(
          id: '$groupId-home-random',
          leagueId: 'atomic-3',
          userId: 'u1',
          groupId: groupId,
        );
        await seedStat(
          id: '$groupId-away-random',
          leagueId: 'atomic-3',
          userId: 'u2',
          groupId: groupId,
        );
      }

      await fs.updateMatchAtomically(
        matchId: matchId,
        leagueId: 'atomic-3',
        homeScore: 2,
        awayScore: 0,
      );

      expect(await statFor('atomic-3', 'u1', groupId: 'A'), {
        GNEsportLeagueStat.fieldUserId: 'u1',
        GNEsportLeagueStat.fieldLeagueId: 'atomic-3',
        GNEsportLeagueStat.fieldMatchesPlayed: 0,
        GNEsportLeagueStat.fieldGoals: 0,
        GNEsportLeagueStat.fieldGoalsConceded: 0,
        GNEsportLeagueStat.fieldWins: 0,
        GNEsportLeagueStat.fieldDraws: 0,
        GNEsportLeagueStat.fieldLosses: 0,
        GNEsportLeagueStat.fieldGroupId: 'A',
      });
      expect(await statFor('atomic-3', 'u1', groupId: 'B'), {
        GNEsportLeagueStat.fieldUserId: 'u1',
        GNEsportLeagueStat.fieldLeagueId: 'atomic-3',
        GNEsportLeagueStat.fieldMatchesPlayed: 1,
        GNEsportLeagueStat.fieldGoals: 2,
        GNEsportLeagueStat.fieldGoalsConceded: 0,
        GNEsportLeagueStat.fieldWins: 1,
        GNEsportLeagueStat.fieldDraws: 0,
        GNEsportLeagueStat.fieldLosses: 0,
        GNEsportLeagueStat.fieldGroupId: 'B',
      });
      expect(await statFor('atomic-3', 'u2', groupId: 'A'), {
        GNEsportLeagueStat.fieldUserId: 'u2',
        GNEsportLeagueStat.fieldLeagueId: 'atomic-3',
        GNEsportLeagueStat.fieldMatchesPlayed: 0,
        GNEsportLeagueStat.fieldGoals: 0,
        GNEsportLeagueStat.fieldGoalsConceded: 0,
        GNEsportLeagueStat.fieldWins: 0,
        GNEsportLeagueStat.fieldDraws: 0,
        GNEsportLeagueStat.fieldLosses: 0,
        GNEsportLeagueStat.fieldGroupId: 'A',
      });
      expect(await statFor('atomic-3', 'u2', groupId: 'B'), {
        GNEsportLeagueStat.fieldUserId: 'u2',
        GNEsportLeagueStat.fieldLeagueId: 'atomic-3',
        GNEsportLeagueStat.fieldMatchesPlayed: 1,
        GNEsportLeagueStat.fieldGoals: 0,
        GNEsportLeagueStat.fieldGoalsConceded: 2,
        GNEsportLeagueStat.fieldWins: 0,
        GNEsportLeagueStat.fieldDraws: 0,
        GNEsportLeagueStat.fieldLosses: 1,
        GNEsportLeagueStat.fieldGroupId: 'B',
      });
    });

    test(
      'knockout writes both next slots and leaves standings unchanged',
      () async {
        final nextId = await seedMatch(
          leagueId: 'atomic-4',
          home: '',
          away: '',
          phase: 'knockout',
        );
        final evenMatchId = await seedMatch(
          leagueId: 'atomic-4',
          home: 'u1',
          away: 'u2',
          phase: 'knockout',
          knockoutSlot: 0,
          nextMatchId: nextId,
        );
        final oddMatchId = await seedMatch(
          leagueId: 'atomic-4',
          home: 'u3',
          away: 'u4',
          phase: 'knockout',
          knockoutSlot: 1,
          nextMatchId: nextId,
        );
        for (final userId in ['u1', 'u2', 'u3', 'u4']) {
          await seedStat(
            id: 'standing-$userId',
            leagueId: 'atomic-4',
            userId: userId,
            matchesPlayed: 5,
            goals: 9,
            goalsConceded: 7,
            wins: 3,
            draws: 1,
            losses: 1,
          );
        }
        final standingsBefore = {
          for (final doc in (await statsCollection('atomic-4').get()).docs)
            doc.id: doc.data(),
        };

        await fs.updateMatchAtomically(
          matchId: evenMatchId,
          leagueId: 'atomic-4',
          homeScore: 2,
          awayScore: 0,
        );
        await fs.updateMatchAtomically(
          matchId: oddMatchId,
          leagueId: 'atomic-4',
          homeScore: 1,
          awayScore: 3,
        );

        final next = (await matchesCollection(
          'atomic-4',
        ).doc(nextId).get()).data()!;
        expect(next[GNEsportMatch.fieldHomeTeamId], 'u1');
        expect(next[GNEsportMatch.fieldAwayTeamId], 'u4');
        expect(
          (await matchesCollection(
            'atomic-4',
          ).doc(evenMatchId).get()).data()?[GNEsportMatch.fieldIsFinished],
          true,
        );
        expect(
          (await matchesCollection(
            'atomic-4',
          ).doc(oddMatchId).get()).data()?[GNEsportMatch.fieldIsFinished],
          true,
        );
        expect({
          for (final doc in (await statsCollection('atomic-4').get()).docs)
            doc.id: doc.data(),
        }, standingsBefore);
      },
    );

    test('missing either stat throws before writing the match', () async {
      for (final missingUserId in ['u1', 'u2']) {
        final leagueId = 'atomic-5-missing-$missingUserId';
        final matchId = await seedMatch(leagueId: leagueId);
        final existingUserId = missingUserId == 'u1' ? 'u2' : 'u1';
        await seedStat(
          id: 'only-existing-stat',
          leagueId: leagueId,
          userId: existingUserId,
        );
        final matchBefore = (await matchesCollection(
          leagueId,
        ).doc(matchId).get()).data();
        final statBefore = await statFor(leagueId, existingUserId);

        await expectLater(
          fs.updateMatchAtomically(
            matchId: matchId,
            leagueId: leagueId,
            homeScore: 1,
            awayScore: 0,
          ),
          throwsA(isA<Exception>()),
        );

        expect(
          (await matchesCollection(leagueId).doc(matchId).get()).data(),
          matchBefore,
        );
        expect(await statFor(leagueId, existingUserId), statBefore);
      }
    });

    test(
      'stat deleted after lookup aborts match, other stat, and next slot writes',
      () async {
        final controlled = _ControlledTransactionFirestore();
        fakeFirestore = controlled;
        fs = GNFirestore(controlled);
        final nextId = await seedMatch(
          leagueId: 'atomic-6',
          home: 'waiting-home',
          away: 'waiting-away',
        );
        final matchId = await seedMatch(
          leagueId: 'atomic-6',
          nextMatchId: nextId,
        );
        final homeStatRef = await seedStat(
          id: 'home-stays',
          leagueId: 'atomic-6',
          userId: 'u1',
        );
        final deletedStatRef = await seedStat(
          id: 'away-deleted-during-update',
          leagueId: 'atomic-6',
          userId: 'u2',
        );
        final matchBefore = (await matchesCollection(
          'atomic-6',
        ).doc(matchId).get()).data();
        final homeBefore = (await homeStatRef.get()).data();
        final nextBefore = (await matchesCollection(
          'atomic-6',
        ).doc(nextId).get()).data();
        controlled.beforeNextTransaction = deletedStatRef.delete;

        await expectLater(
          fs.updateMatchAtomically(
            matchId: matchId,
            leagueId: 'atomic-6',
            homeScore: 2,
            awayScore: 1,
          ),
          throwsA(isA<Exception>()),
        );

        expect(
          (await matchesCollection('atomic-6').doc(matchId).get()).data(),
          matchBefore,
        );
        expect((await homeStatRef.get()).data(), homeBefore);
        expect((await deletedStatRef.get()).exists, false);
        expect(
          (await matchesCollection('atomic-6').doc(nextId).get()).data(),
          nextBefore,
        );
      },
    );

    test('stale expectedUpdatedAt writes no document', () async {
      final currentVersion = Timestamp.fromDate(DateTime(2026, 7, 2));
      final staleVersion = Timestamp.fromDate(DateTime(2026, 7, 1));
      final matchId = await seedMatch(
        leagueId: 'atomic-7',
        updatedAt: currentVersion,
      );
      final homeRef = await seedStat(
        id: 'stale-home',
        leagueId: 'atomic-7',
        userId: 'u1',
      );
      final awayRef = await seedStat(
        id: 'stale-away',
        leagueId: 'atomic-7',
        userId: 'u2',
      );
      final matchBefore = (await matchesCollection(
        'atomic-7',
      ).doc(matchId).get()).data();
      final homeBefore = (await homeRef.get()).data();
      final awayBefore = (await awayRef.get()).data();

      await expectLater(
        fs.updateMatchAtomically(
          matchId: matchId,
          leagueId: 'atomic-7',
          homeScore: 7,
          awayScore: 0,
          expectedUpdatedAt: staleVersion,
        ),
        throwsA(isA<ConcurrentMatchUpdateException>()),
      );

      expect(
        (await matchesCollection('atomic-7').doc(matchId).get()).data(),
        matchBefore,
      );
      expect((await homeRef.get()).data(), homeBefore);
      expect((await awayRef.get()).data(), awayBefore);
    });

    test(
      'legacy null timestamp updates once then rejects a stale version',
      () async {
        final matchId = await seedMatch(leagueId: 'atomic-8');
        await seedStat(id: 'legacy-home', leagueId: 'atomic-8', userId: 'u1');
        await seedStat(id: 'legacy-away', leagueId: 'atomic-8', userId: 'u2');

        await fs.updateMatchAtomically(
          matchId: matchId,
          leagueId: 'atomic-8',
          homeScore: 2,
          awayScore: 1,
        );
        final firstWrite = (await matchesCollection(
          'atomic-8',
        ).doc(matchId).get()).data()!;
        expect(firstWrite[GNEsportMatch.fieldUpdatedAt], isA<Timestamp>());

        await expectLater(
          fs.updateMatchAtomically(
            matchId: matchId,
            leagueId: 'atomic-8',
            homeScore: 0,
            awayScore: 3,
            expectedUpdatedAt: Timestamp.fromDate(DateTime(2020)),
          ),
          throwsA(isA<ConcurrentMatchUpdateException>()),
        );

        final afterConflict = (await matchesCollection(
          'atomic-8',
        ).doc(matchId).get()).data()!;
        expect(afterConflict[GNEsportMatch.fieldHomeScore], 2);
        expect(afterConflict[GNEsportMatch.fieldAwayScore], 1);
        expect(await statFor('atomic-8', 'u1'), {
          GNEsportLeagueStat.fieldUserId: 'u1',
          GNEsportLeagueStat.fieldLeagueId: 'atomic-8',
          GNEsportLeagueStat.fieldMatchesPlayed: 1,
          GNEsportLeagueStat.fieldGoals: 2,
          GNEsportLeagueStat.fieldGoalsConceded: 1,
          GNEsportLeagueStat.fieldWins: 1,
          GNEsportLeagueStat.fieldDraws: 0,
          GNEsportLeagueStat.fieldLosses: 0,
        });
        expect(await statFor('atomic-8', 'u2'), {
          GNEsportLeagueStat.fieldUserId: 'u2',
          GNEsportLeagueStat.fieldLeagueId: 'atomic-8',
          GNEsportLeagueStat.fieldMatchesPlayed: 1,
          GNEsportLeagueStat.fieldGoals: 1,
          GNEsportLeagueStat.fieldGoalsConceded: 2,
          GNEsportLeagueStat.fieldWins: 0,
          GNEsportLeagueStat.fieldDraws: 0,
          GNEsportLeagueStat.fieldLosses: 1,
        });
      },
    );

    test(
      'concurrent legacy null version allows one success and one conflict',
      () async {
        final controlled = _ControlledTransactionFirestore();
        fakeFirestore = controlled;
        fs = GNFirestore(controlled);
        final matchId = await seedMatch(leagueId: 'atomic-legacy-race');
        await seedStat(
          id: 'legacy-race-home-random',
          leagueId: 'atomic-legacy-race',
          userId: 'u1',
        );
        await seedStat(
          id: 'legacy-race-away-random',
          leagueId: 'atomic-legacy-race',
          userId: 'u2',
        );

        final outcomes = await Future.wait([
          capture(
            fs.updateMatchAtomically(
              matchId: matchId,
              leagueId: 'atomic-legacy-race',
              homeScore: 2,
              awayScore: 0,
              expectedUpdatedAt: null,
            ),
          ),
          capture(
            fs.updateMatchAtomically(
              matchId: matchId,
              leagueId: 'atomic-legacy-race',
              homeScore: 4,
              awayScore: 1,
              expectedUpdatedAt: null,
            ),
          ),
        ]);

        expect(outcomes.where((result) => result == null), hasLength(1));
        expect(
          outcomes.whereType<ConcurrentMatchUpdateException>(),
          hasLength(1),
        );
        final match = (await matchesCollection(
          'atomic-legacy-race',
        ).doc(matchId).get()).data()!;
        final homeStat = await statFor('atomic-legacy-race', 'u1');
        final awayStat = await statFor('atomic-legacy-race', 'u2');
        expect(match[GNEsportMatch.fieldUpdatedAt], isA<Timestamp>());
        expect(
          (
            homeScore: match[GNEsportMatch.fieldHomeScore],
            awayScore: match[GNEsportMatch.fieldAwayScore],
            homeGoals: homeStat[GNEsportLeagueStat.fieldGoals],
            homeConceded: homeStat[GNEsportLeagueStat.fieldGoalsConceded],
            awayGoals: awayStat[GNEsportLeagueStat.fieldGoals],
            awayConceded: awayStat[GNEsportLeagueStat.fieldGoalsConceded],
          ),
          anyOf(
            (
              homeScore: 2,
              awayScore: 0,
              homeGoals: 2,
              homeConceded: 0,
              awayGoals: 0,
              awayConceded: 2,
            ),
            (
              homeScore: 4,
              awayScore: 1,
              homeGoals: 4,
              homeConceded: 1,
              awayGoals: 1,
              awayConceded: 4,
            ),
          ),
        );
        expect(homeStat[GNEsportLeagueStat.fieldMatchesPlayed], 1);
        expect(homeStat[GNEsportLeagueStat.fieldWins], 1);
        expect(homeStat[GNEsportLeagueStat.fieldDraws], 0);
        expect(homeStat[GNEsportLeagueStat.fieldLosses], 0);
        expect(awayStat[GNEsportLeagueStat.fieldMatchesPlayed], 1);
        expect(awayStat[GNEsportLeagueStat.fieldWins], 0);
        expect(awayStat[GNEsportLeagueStat.fieldDraws], 0);
        expect(awayStat[GNEsportLeagueStat.fieldLosses], 1);
      },
    );

    test(
      'concurrent different matches sharing a player preserve both deltas',
      () async {
        final controlled = _ControlledTransactionFirestore();
        fakeFirestore = controlled;
        fs = GNFirestore(controlled);
        final firstVersion = Timestamp.fromDate(DateTime(2026, 8, 1, 10));
        final secondVersion = Timestamp.fromDate(DateTime(2026, 8, 1, 11));
        final firstMatchId = await seedMatch(
          leagueId: 'atomic-9',
          home: 'u1',
          away: 'u2',
          updatedAt: firstVersion,
        );
        final secondMatchId = await seedMatch(
          leagueId: 'atomic-9',
          home: 'u3',
          away: 'u1',
          updatedAt: secondVersion,
        );
        for (final userId in ['u1', 'u2', 'u3']) {
          await seedStat(
            id: 'shared-$userId',
            leagueId: 'atomic-9',
            userId: userId,
          );
        }

        await Future.wait<void>([
          () async {
            await fs.updateMatchAtomically(
              matchId: firstMatchId,
              leagueId: 'atomic-9',
              homeScore: 2,
              awayScore: 0,
              expectedUpdatedAt: firstVersion,
            );
          }(),
          () async {
            await fs.updateMatchAtomically(
              matchId: secondMatchId,
              leagueId: 'atomic-9',
              homeScore: 1,
              awayScore: 3,
              expectedUpdatedAt: secondVersion,
            );
          }(),
        ]);

        expect(await statFor('atomic-9', 'u1'), {
          GNEsportLeagueStat.fieldUserId: 'u1',
          GNEsportLeagueStat.fieldLeagueId: 'atomic-9',
          GNEsportLeagueStat.fieldMatchesPlayed: 2,
          GNEsportLeagueStat.fieldGoals: 5,
          GNEsportLeagueStat.fieldGoalsConceded: 1,
          GNEsportLeagueStat.fieldWins: 2,
          GNEsportLeagueStat.fieldDraws: 0,
          GNEsportLeagueStat.fieldLosses: 0,
        });
        expect(await statFor('atomic-9', 'u2'), {
          GNEsportLeagueStat.fieldUserId: 'u2',
          GNEsportLeagueStat.fieldLeagueId: 'atomic-9',
          GNEsportLeagueStat.fieldMatchesPlayed: 1,
          GNEsportLeagueStat.fieldGoals: 0,
          GNEsportLeagueStat.fieldGoalsConceded: 2,
          GNEsportLeagueStat.fieldWins: 0,
          GNEsportLeagueStat.fieldDraws: 0,
          GNEsportLeagueStat.fieldLosses: 1,
        });
        expect(await statFor('atomic-9', 'u3'), {
          GNEsportLeagueStat.fieldUserId: 'u3',
          GNEsportLeagueStat.fieldLeagueId: 'atomic-9',
          GNEsportLeagueStat.fieldMatchesPlayed: 1,
          GNEsportLeagueStat.fieldGoals: 1,
          GNEsportLeagueStat.fieldGoalsConceded: 3,
          GNEsportLeagueStat.fieldWins: 0,
          GNEsportLeagueStat.fieldDraws: 0,
          GNEsportLeagueStat.fieldLosses: 1,
        });
      },
    );

    test(
      'concurrent same version allows one success and one conflict',
      () async {
        final controlled = _ControlledTransactionFirestore();
        fakeFirestore = controlled;
        fs = GNFirestore(controlled);
        final version = Timestamp.fromDate(DateTime(2026, 8, 2));
        final matchId = await seedMatch(
          leagueId: 'atomic-10',
          updatedAt: version,
        );
        await seedStat(
          id: 'conflict-home',
          leagueId: 'atomic-10',
          userId: 'u1',
        );
        await seedStat(
          id: 'conflict-away',
          leagueId: 'atomic-10',
          userId: 'u2',
        );

        final outcomes = await Future.wait([
          capture(
            fs.updateMatchAtomically(
              matchId: matchId,
              leagueId: 'atomic-10',
              homeScore: 2,
              awayScore: 0,
              expectedUpdatedAt: version,
            ),
          ),
          capture(
            fs.updateMatchAtomically(
              matchId: matchId,
              leagueId: 'atomic-10',
              homeScore: 4,
              awayScore: 1,
              expectedUpdatedAt: version,
            ),
          ),
        ]);

        expect(outcomes.where((result) => result == null), hasLength(1));
        expect(
          outcomes.whereType<ConcurrentMatchUpdateException>(),
          hasLength(1),
        );
        final match = (await matchesCollection(
          'atomic-10',
        ).doc(matchId).get()).data()!;
        final homeStat = await statFor('atomic-10', 'u1');
        final awayStat = await statFor('atomic-10', 'u2');
        expect(
          (
            homeScore: match[GNEsportMatch.fieldHomeScore],
            awayScore: match[GNEsportMatch.fieldAwayScore],
            homeGoals: homeStat[GNEsportLeagueStat.fieldGoals],
            homeConceded: homeStat[GNEsportLeagueStat.fieldGoalsConceded],
            awayGoals: awayStat[GNEsportLeagueStat.fieldGoals],
            awayConceded: awayStat[GNEsportLeagueStat.fieldGoalsConceded],
          ),
          anyOf(
            (
              homeScore: 2,
              awayScore: 0,
              homeGoals: 2,
              homeConceded: 0,
              awayGoals: 0,
              awayConceded: 2,
            ),
            (
              homeScore: 4,
              awayScore: 1,
              homeGoals: 4,
              homeConceded: 1,
              awayGoals: 1,
              awayConceded: 4,
            ),
          ),
        );
        expect(homeStat[GNEsportLeagueStat.fieldMatchesPlayed], 1);
        expect(homeStat[GNEsportLeagueStat.fieldWins], 1);
        expect(awayStat[GNEsportLeagueStat.fieldMatchesPlayed], 1);
        expect(awayStat[GNEsportLeagueStat.fieldLosses], 1);
      },
    );
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
      final matchId = await seedMatch(leagueId: 'L1');
      await fs.updateMatchAtomically(
        matchId: matchId,
        leagueId: 'L1',
        homeScore: 3,
        awayScore: 1,
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
