import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/presentation/home/widgets/ongoing_tournaments_banner.dart';

GNEsportLeague _league({
  required String id,
  String? status,
}) => GNEsportLeague(
  id: id,
  ownerId: 'u1',
  groupId: 'g1',
  name: 'L $id',
  startDate: DateTime(2026, 5, 1),
  endDate: DateTime(2026, 5, 10),
  isActive: true,
  description: '',
  participants: const [],
  rankPayoutEnabled: false,
  rankPayouts: const [],
  defaultMatchCost: 0,
  status: status,
);

void main() {
  test('giữ giải đấu có status = ongoing', () {
    final result = filterOngoingLeagues([
      _league(id: 'a', status: 'ongoing'),
      _league(id: 'b', status: 'ongoing'),
    ]);
    expect(result.map((l) => l.id), ['a', 'b']);
  });

  test('loại giải đấu có status = finished dù endDate còn trong tương lai', () {
    final result = filterOngoingLeagues([
      _league(id: 'done', status: 'finished'),
    ]);
    expect(result, isEmpty);
  });

  test('loại giải đấu có status = upcoming', () {
    final result = filterOngoingLeagues([
      _league(id: 'soon', status: 'upcoming'),
    ]);
    expect(result, isEmpty);
  });

  test('status null/legacy → coi như upcoming, không hiện trên banner', () {
    final result = filterOngoingLeagues([
      _league(id: 'legacy', status: null),
    ]);
    expect(result, isEmpty);
  });

  test('lọc đúng tập con khi mix status', () {
    final result = filterOngoingLeagues([
      _league(id: 'a', status: 'ongoing'),
      _league(id: 'b', status: 'finished'),
      _league(id: 'c', status: 'upcoming'),
      _league(id: 'd', status: 'ongoing'),
    ]);
    expect(result.map((l) => l.id), ['a', 'd']);
  });
}
