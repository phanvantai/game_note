import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/matches/fixture_grouping.dart';

void main() {
  GNEsportMatch match(String id, {int? matchday}) {
    return GNEsportMatch(
      id: id,
      homeTeamId: 'home-$id',
      awayTeamId: 'away-$id',
      date: DateTime(2026, 5, 10),
      isFinished: false,
      leagueId: 'L1',
      matchday: matchday,
    );
  }

  group('groupFixturesByMatchday', () {
    test('nhóm theo vòng và sắp xếp tăng dần', () {
      final sections = groupFixturesByMatchday([
        match('c', matchday: 3),
        match('a', matchday: 1),
        match('b', matchday: 2),
      ]);

      expect(sections.map((s) => s.matchday).toList(), [1, 2, 3]);
      expect(sections.map((s) => s.matches.single.id).toList(), [
        'a',
        'b',
        'c',
      ]);
    });

    test('gom nhiều trận cùng vòng vào một section', () {
      final sections = groupFixturesByMatchday([
        match('a', matchday: 1),
        match('b', matchday: 1),
        match('c', matchday: 2),
      ]);

      expect(sections, hasLength(2));
      expect(sections.first.matches.map((m) => m.id).toList(), ['a', 'b']);
      expect(sections.last.matches.map((m) => m.id).toList(), ['c']);
    });

    test('trận không có vòng nằm ở section cuối', () {
      final sections = groupFixturesByMatchday([
        match('custom'),
        match('a', matchday: 2),
        match('legacy'),
        match('b', matchday: 1),
      ]);

      expect(sections.map((s) => s.matchday).toList(), [1, 2, null]);
      expect(sections.last.matches.map((m) => m.id).toList(), [
        'custom',
        'legacy',
      ]);
    });

    test('isOther đánh dấu đúng section không có vòng', () {
      final sections = groupFixturesByMatchday([
        match('a', matchday: 1),
        match('custom'),
      ]);

      expect(sections.first.isOther, isFalse);
      expect(sections.last.isOther, isTrue);
    });

    test('danh sách rỗng trả về không section nào', () {
      expect(groupFixturesByMatchday(const []), isEmpty);
    });

    test('toàn trận không có vòng chỉ tạo section "khác"', () {
      final sections = groupFixturesByMatchday([match('a'), match('b')]);

      expect(sections, hasLength(1));
      expect(sections.single.isOther, isTrue);
      expect(sections.single.matches, hasLength(2));
    });

    test('số vòng bị đứt quãng vẫn giữ nguyên, không đánh số lại', () {
      final sections = groupFixturesByMatchday([
        match('a', matchday: 1),
        match('b', matchday: 7),
      ]);

      expect(sections.map((s) => s.matchday).toList(), [1, 7]);
    });

    test('giữ nguyên thứ tự trận trong cùng một vòng', () {
      final sections = groupFixturesByMatchday([
        match('z', matchday: 1),
        match('a', matchday: 1),
      ]);

      expect(sections.single.matches.map((m) => m.id).toList(), ['z', 'a']);
    });
  });

  group('FixtureSection', () {
    test('so sánh bằng giá trị', () {
      final a = FixtureSection(matchday: 1, matches: [match('a', matchday: 1)]);
      final b = FixtureSection(matchday: 1, matches: [match('a', matchday: 1)]);

      expect(a, b);
      expect(a, isNot(FixtureSection(matchday: 2, matches: a.matches)));
    });
  });
}
