import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/presentation/home/dashboard/models/opponent_stat.dart';

void main() {
  test('rate trả về 0 khi matchesPlayed = 0; tỉ lệ đúng khi có trận', () {
    const empty = OpponentStat(
      opponentId: 'u',
      opponentDisplayName: '',
      matchesPlayed: 0,
      wins: 0,
      draws: 0,
      losses: 0,
    );
    expect(empty.rate(0), 0);

    const o = OpponentStat(
      opponentId: 'u',
      opponentDisplayName: 'P',
      matchesPlayed: 4,
      wins: 3,
      draws: 0,
      losses: 1,
    );
    expect(o.rate(o.wins), closeTo(0.75, 1e-9));
    expect(o.rate(o.losses), closeTo(0.25, 1e-9));
    expect(o.props.length, 7);
  });

  test('Equatable equality theo từng field', () {
    const a = OpponentStat(
      opponentId: 'u',
      opponentDisplayName: 'P',
      matchesPlayed: 1,
      wins: 1,
      draws: 0,
      losses: 0,
    );
    const b = OpponentStat(
      opponentId: 'u',
      opponentDisplayName: 'P',
      matchesPlayed: 1,
      wins: 1,
      draws: 0,
      losses: 0,
    );
    expect(a, equals(b));
  });
}
