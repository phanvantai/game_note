import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/league/gn_esport_league.dart';
import 'package:pes_arena/presentation/home/widgets/ongoing_tournaments_banner.dart';

GNEsportLeague _league({
  required String id,
  required DateTime start,
  DateTime? end,
}) => GNEsportLeague(
  id: id,
  ownerId: 'u1',
  groupId: 'g1',
  name: 'L $id',
  startDate: start,
  endDate: end,
  isActive: true,
  description: '',
  participants: const [],
  rankPayoutEnabled: false,
  rankPayouts: const [],
  defaultMatchCost: 0,
);

void main() {
  final now = DateTime(2026, 5, 4, 14, 30);

  test('giữ giải đấu mà today nằm trong [startDate, endDate]', () {
    final result = filterOngoingLeagues([
      _league(
        id: 'a',
        start: DateTime(2026, 5, 1),
        end: DateTime(2026, 5, 10),
      ),
      _league(id: 'b', start: DateTime(2026, 5, 4), end: DateTime(2026, 5, 4)),
    ], now);
    expect(result.map((l) => l.id), ['a', 'b']);
  });

  test('loại giải đấu đã kết thúc hoặc chưa bắt đầu', () {
    final result = filterOngoingLeagues([
      _league(
        id: 'past',
        start: DateTime(2026, 4, 1),
        end: DateTime(2026, 4, 30),
      ),
      _league(id: 'future', start: DateTime(2026, 6, 1)),
    ], now);
    expect(result, isEmpty);
  });

  test('endDate null thì coi như cùng ngày với startDate', () {
    final result = filterOngoingLeagues([
      _league(id: 'today', start: DateTime(2026, 5, 4)),
      _league(id: 'yesterday', start: DateTime(2026, 5, 3)),
    ], now);
    expect(result.map((l) => l.id), ['today']);
  });
}
