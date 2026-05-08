import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';

GNEsportLeagueStat _stat({String? groupId}) => GNEsportLeagueStat(
      id: 'S1',
      userId: 'U1',
      leagueId: 'L1',
      matchesPlayed: 5,
      goals: 10,
      goalsConceded: 4,
      wins: 3,
      draws: 1,
      losses: 1,
      groupId: groupId,
    );

Map<String, dynamic> _baseMap({String? groupId}) {
  final map = <String, dynamic>{
    GNEsportLeagueStat.fieldUserId: 'U1',
    GNEsportLeagueStat.fieldLeagueId: 'L1',
    GNEsportLeagueStat.fieldMatchesPlayed: 5,
    GNEsportLeagueStat.fieldGoals: 10,
    GNEsportLeagueStat.fieldGoalsConceded: 4,
    GNEsportLeagueStat.fieldWins: 3,
    GNEsportLeagueStat.fieldDraws: 1,
    GNEsportLeagueStat.fieldLosses: 1,
  };
  if (groupId != null) map[GNEsportLeagueStat.fieldGroupId] = groupId;
  return map;
}

void main() {
  group('GNEsportLeagueStat.toMap — groupId', () {
    test('groupId null → key không xuất hiện trong map', () {
      final map = _stat(groupId: null).toMap();
      expect(map.containsKey(GNEsportLeagueStat.fieldGroupId), isFalse);
    });

    test('groupId có giá trị → key xuất hiện với đúng value', () {
      final map = _stat(groupId: 'GA').toMap();
      expect(map[GNEsportLeagueStat.fieldGroupId], 'GA');
    });
  });

  group('GNEsportLeagueStat.fromMap — groupId', () {
    test('document có groupId → giữ nguyên', () {
      final restored = GNEsportLeagueStat.fromMap(_baseMap(groupId: 'GB'), 'S2');
      expect(restored.groupId, 'GB');
    });

    test('document không có groupId → null', () {
      final restored = GNEsportLeagueStat.fromMap(_baseMap(), 'S3');
      expect(restored.groupId, isNull);
    });

    test('roundtrip toMap → fromMap giữ nguyên groupId', () {
      final original = _stat(groupId: 'GC');
      final map = Map<String, dynamic>.from(original.toMap());
      final restored = GNEsportLeagueStat.fromMap(map, original.id);
      expect(restored.groupId, 'GC');
    });
  });
}
