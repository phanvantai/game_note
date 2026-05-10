import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';

GNEsportLeague _league({
  bool rankPayoutEnabled = false,
  List<int> rankPayouts = const [],
  int defaultMatchCost = 50000,
  bool defaultPerGoalEnabled = false,
  int defaultCostPerGoal = 50000,
}) {
  return GNEsportLeague(
    id: 'L1',
    ownerId: 'owner',
    groupId: 'G1',
    name: 'Test League',
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 2, 1),
    isActive: true,
    description: 'desc',
    participants: const ['u1', 'u2'],
    status: 'ongoing',
    rankPayoutEnabled: rankPayoutEnabled,
    rankPayouts: rankPayouts,
    defaultMatchCost: defaultMatchCost,
    defaultPerGoalEnabled: defaultPerGoalEnabled,
    defaultCostPerGoal: defaultCostPerGoal,
  );
}

void main() {
  group('GNEsportLeague.toMap', () {
    test('persist các field cost mới', () {
      final map = _league(
        rankPayoutEnabled: true,
        rankPayouts: [50000, 100000, 150000],
        defaultMatchCost: 75000,
        defaultPerGoalEnabled: true,
        defaultCostPerGoal: 60000,
      ).toMap();

      expect(map[GNEsportLeague.fieldRankPayoutEnabled], isTrue);
      expect(map[GNEsportLeague.fieldRankPayouts], [50000, 100000, 150000]);
      expect(map[GNEsportLeague.fieldDefaultMatchCost], 75000);
      expect(map[GNEsportLeague.fieldDefaultPerGoalEnabled], isTrue);
      expect(map[GNEsportLeague.fieldDefaultCostPerGoal], 60000);
    });

    test('không có key matchCostEnabled (đã bỏ)', () {
      final map = _league().toMap();
      expect(map.containsKey('matchCostEnabled'), isFalse);
    });
  });

  group('GNEsportLeague.fromMap', () {
    test('roundtrip toMap → fromMap giữ nguyên các field cost', () {
      final original = _league(
        rankPayoutEnabled: true,
        rankPayouts: [50000, 100000],
        defaultMatchCost: 80000,
        defaultPerGoalEnabled: true,
        defaultCostPerGoal: 60000,
      );
      // toMap không bao gồm `id` (Firestore tự gán doc.id) — phải truyền lại.
      final map = Map<String, dynamic>.from(original.toMap());
      // toMap dùng Timestamp; fromMap chấp nhận DateTime nên truyền raw DateTime.
      map[GNEsportLeague.fieldStartDate] = original.startDate;
      map[GNEsportLeague.fieldEndDate] = original.endDate;
      final restored = GNEsportLeague.fromMap(map, original.id);

      expect(restored.rankPayoutEnabled, true);
      expect(restored.rankPayouts, [50000, 100000]);
      expect(restored.defaultMatchCost, 80000);
      expect(restored.defaultPerGoalEnabled, true);
      expect(restored.defaultCostPerGoal, 60000);
    });

    test('document cũ thiếu field cost: fallback về default (an toàn)', () {
      // Mô phỏng document được tạo trước khi feature được thêm.
      final legacyData = <String, dynamic>{
        GNEsportLeague.fieldOwnerId: 'owner',
        GNEsportLeague.fieldGroupId: 'G1',
        GNEsportLeague.fieldName: 'Old League',
        GNEsportLeague.fieldStartDate: DateTime(2025, 1, 1),
        GNEsportLeague.fieldIsActive: true,
        GNEsportLeague.fieldDescription: '',
        GNEsportLeague.fieldParticipants: <String>[],
        GNEsportLeague.fieldStatus: 'finished',
        // Không có rankPayoutEnabled, rankPayouts, defaultMatchCost
      };
      final restored = GNEsportLeague.fromMap(legacyData, 'old');

      expect(restored.rankPayoutEnabled, false);
      expect(restored.rankPayouts, isEmpty);
      expect(restored.defaultMatchCost, 50000);
      expect(restored.defaultPerGoalEnabled, false);
      expect(restored.defaultCostPerGoal, 50000);
    });

    test('rankPayouts là List<dynamic> (Firestore trả): parse thành List<int>',
        () {
      final data = <String, dynamic>{
        GNEsportLeague.fieldOwnerId: 'owner',
        GNEsportLeague.fieldGroupId: 'G1',
        GNEsportLeague.fieldName: 'L',
        GNEsportLeague.fieldStartDate: DateTime(2026, 1, 1),
        GNEsportLeague.fieldIsActive: true,
        GNEsportLeague.fieldDescription: '',
        GNEsportLeague.fieldParticipants: <String>[],
        GNEsportLeague.fieldRankPayoutEnabled: true,
        GNEsportLeague.fieldRankPayouts: <dynamic>[50000, 100000, 150000],
        GNEsportLeague.fieldDefaultMatchCost: 60000,
      };
      final restored = GNEsportLeague.fromMap(data, 'x');
      expect(restored.rankPayouts, [50000, 100000, 150000]);
    });

    test('fromMap không có startDate: dùng DateTime.now()', () {
      final data = <String, dynamic>{
        GNEsportLeague.fieldOwnerId: 'owner',
        GNEsportLeague.fieldGroupId: 'G1',
        GNEsportLeague.fieldName: 'L',
        GNEsportLeague.fieldIsActive: true,
        GNEsportLeague.fieldDescription: '',
        GNEsportLeague.fieldParticipants: <String>[],
      };
      final before = DateTime.now();
      final restored = GNEsportLeague.fromMap(data, 'x');
      final after = DateTime.now();
      expect(restored.startDate.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(restored.startDate.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('fromMap với type lạ ở date field: trả null cho endDate', () {
      final data = <String, dynamic>{
        GNEsportLeague.fieldOwnerId: 'owner',
        GNEsportLeague.fieldGroupId: 'G1',
        GNEsportLeague.fieldName: 'L',
        GNEsportLeague.fieldStartDate: DateTime(2026, 1, 1),
        GNEsportLeague.fieldEndDate: 'not-a-date',
        GNEsportLeague.fieldIsActive: true,
        GNEsportLeague.fieldDescription: '',
        GNEsportLeague.fieldParticipants: <String>[],
      };
      final restored = GNEsportLeague.fromMap(data, 'x');
      expect(restored.endDate, isNull);
    });
  });

  group('GNEsportLeague.copyWith', () {
    test('không truyền tham số: identical content', () {
      final l = _league();
      final copy = l.copyWith();
      expect(copy.id, l.id);
      expect(copy.name, l.name);
      expect(copy.rankPayoutEnabled, l.rankPayoutEnabled);
    });

    test('override từng field một cách độc lập', () {
      final original = _league();
      final copy = original.copyWith(
        id: 'L2',
        ownerId: 'newOwner',
        groupId: 'G2',
        name: 'New Name',
        startDate: DateTime(2027, 1, 1),
        endDate: DateTime(2027, 2, 1),
        isActive: false,
        description: 'new',
        participants: const ['x'],
        status: 'finished',
        rankPayoutEnabled: true,
        rankPayouts: const [50000],
        defaultMatchCost: 99000,
        defaultPerGoalEnabled: true,
        defaultCostPerGoal: 70000,
      );
      expect(copy.id, 'L2');
      expect(copy.ownerId, 'newOwner');
      expect(copy.groupId, 'G2');
      expect(copy.name, 'New Name');
      expect(copy.startDate, DateTime(2027, 1, 1));
      expect(copy.endDate, DateTime(2027, 2, 1));
      expect(copy.isActive, false);
      expect(copy.description, 'new');
      expect(copy.participants, ['x']);
      expect(copy.status, 'finished');
      expect(copy.rankPayoutEnabled, true);
      expect(copy.rankPayouts, [50000]);
      expect(copy.defaultMatchCost, 99000);
      expect(copy.defaultPerGoalEnabled, true);
      expect(copy.defaultCostPerGoal, 70000);
    });

    test('props equality: 2 instance cùng data thì equal', () {
      expect(_league() == _league(), isTrue);
    });
  });

  group('GNEsportLeagueStatus extension', () {
    test('value', () {
      expect(GNEsportLeagueStatus.upcoming.value, 'upcoming');
      expect(GNEsportLeagueStatus.ongoing.value, 'ongoing');
      expect(GNEsportLeagueStatus.finished.value, 'finished');
    });

    test('name (display vi)', () {
      expect(GNEsportLeagueStatus.upcoming.name, 'Sắp diễn ra');
      expect(GNEsportLeagueStatus.ongoing.name, 'Đang diễn ra');
      expect(GNEsportLeagueStatus.finished.name, 'Đã kết thúc');
    });

    test('color: mỗi status 1 màu', () {
      expect(GNEsportLeagueStatus.upcoming.color, isA<Color>());
      expect(GNEsportLeagueStatus.ongoing.color, isA<Color>());
      expect(GNEsportLeagueStatus.finished.color, isA<Color>());
      expect(
        GNEsportLeagueStatus.upcoming.color !=
            GNEsportLeagueStatus.ongoing.color,
        isTrue,
      );
    });

    test('fromString: parse đúng cho 3 case', () {
      expect(
        GNEsportLeagueStatusExtension.fromString('upcoming'),
        GNEsportLeagueStatus.upcoming,
      );
      expect(
        GNEsportLeagueStatusExtension.fromString('ongoing'),
        GNEsportLeagueStatus.ongoing,
      );
      expect(
        GNEsportLeagueStatusExtension.fromString('finished'),
        GNEsportLeagueStatus.finished,
      );
    });

    test('fromString: null hoặc lạ ⇒ fallback upcoming', () {
      expect(
        GNEsportLeagueStatusExtension.fromString(null),
        GNEsportLeagueStatus.upcoming,
      );
      expect(
        GNEsportLeagueStatusExtension.fromString('what?'),
        GNEsportLeagueStatus.upcoming,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // TournamentMode
  // ---------------------------------------------------------------------------

  group('TournamentMode.fromString', () {
    test('"cup" → TournamentMode.cup', () {
      expect(TournamentModeExtension.fromString('cup'), TournamentMode.cup);
    });

    test('"full" → TournamentMode.full', () {
      expect(TournamentModeExtension.fromString('full'), TournamentMode.full);
    });

    test('"league" → TournamentMode.league', () {
      expect(
          TournamentModeExtension.fromString('league'), TournamentMode.league);
    });

    test('null hoặc lạ → fallback TournamentMode.league', () {
      expect(TournamentModeExtension.fromString(null), TournamentMode.league);
      expect(
          TournamentModeExtension.fromString('unknown'), TournamentMode.league);
    });
  });

  group('TournamentMode.value', () {
    test('league → "league"', () {
      expect(TournamentMode.league.value, 'league');
    });
    test('cup → "cup"', () {
      expect(TournamentMode.cup.value, 'cup');
    });
    test('full → "full"', () {
      expect(TournamentMode.full.value, 'full');
    });
  });

  group('GNEsportLeague mode/groupCount/advanceCount/knockoutSeeding', () {
    test('toMap persist mode, groupCount, advanceCount, knockoutSeeding', () {
      final league = GNEsportLeague(
        id: 'L1',
        ownerId: 'owner',
        groupId: 'G1',
        name: 'Full League',
        startDate: DateTime(2026, 1, 1),
        isActive: true,
        description: '',
        participants: const [],
        mode: TournamentMode.full,
        groupCount: 4,
        advanceCount: 2,
        knockoutSeeding: const ['U1', 'U2'],
      );
      final map = league.toMap();

      expect(map[GNEsportLeague.fieldMode], 'full');
      expect(map[GNEsportLeague.fieldGroupCount], 4);
      expect(map[GNEsportLeague.fieldAdvanceCount], 2);
      expect(map[GNEsportLeague.fieldKnockoutSeeding], ['U1', 'U2']);
    });

    test('fromMap roundtrip giữ nguyên mode full + groupCount + advanceCount', () {
      final original = GNEsportLeague(
        id: 'L1',
        ownerId: 'owner',
        groupId: 'G1',
        name: 'Full',
        startDate: DateTime(2026, 1, 1),
        isActive: true,
        description: '',
        participants: const [],
        mode: TournamentMode.full,
        groupCount: 2,
        advanceCount: 1,
        knockoutSeeding: const ['U3'],
      );
      final map = Map<String, dynamic>.from(original.toMap());
      map[GNEsportLeague.fieldStartDate] = original.startDate;
      final restored = GNEsportLeague.fromMap(map, original.id);

      expect(restored.mode, TournamentMode.full);
      expect(restored.groupCount, 2);
      expect(restored.advanceCount, 1);
      expect(restored.knockoutSeeding, ['U3']);
    });

    test('document cũ thiếu mode → fallback TournamentMode.league', () {
      final legacy = <String, dynamic>{
        GNEsportLeague.fieldOwnerId: 'owner',
        GNEsportLeague.fieldGroupId: 'G1',
        GNEsportLeague.fieldName: 'Old',
        GNEsportLeague.fieldStartDate: DateTime(2025, 1, 1),
        GNEsportLeague.fieldIsActive: true,
        GNEsportLeague.fieldDescription: '',
        GNEsportLeague.fieldParticipants: <String>[],
      };
      final restored = GNEsportLeague.fromMap(legacy, 'old');

      expect(restored.mode, TournamentMode.league);
      expect(restored.groupCount, 1);
      expect(restored.advanceCount, 2);
      expect(restored.knockoutSeeding, isEmpty);
    });
  });
}
