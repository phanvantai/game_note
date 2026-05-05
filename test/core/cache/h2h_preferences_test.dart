import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/core/cache/h2h_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late H2HPreferences prefs;

  Future<H2HPreferences> create([Map<String, Object>? seed]) async {
    SharedPreferences.setMockInitialValues(seed ?? {});
    final sp = await SharedPreferences.getInstance();
    return H2HPreferences(sp);
  }

  setUp(() async {
    prefs = await create();
  });

  test('default khi chưa lưu = 50', () {
    expect(prefs.minMatches, H2HPreferences.defaultMinMatches);
    expect(H2HPreferences.defaultMinMatches, 50);
  });

  test('set + get round-trip trong khoảng cho phép', () async {
    await prefs.setMinMatches(50);
    final reloaded = await create({
      'dashboard.h2h.min_matches': 50,
    });
    expect(reloaded.minMatches, 50);
  });

  test('set giá trị ngoài bound bị clamp về biên', () async {
    await prefs.setMinMatches(9999);
    final hi = await create({'dashboard.h2h.min_matches': 9999});
    expect(hi.minMatches, H2HPreferences.maxBound);

    await prefs.setMinMatches(-5);
    final lo = await create({'dashboard.h2h.min_matches': -5});
    expect(lo.minMatches, H2HPreferences.minBound);
  });

  test('giá trị stored hợp lệ được trả nguyên', () async {
    final p = await create({'dashboard.h2h.min_matches': 75});
    expect(p.minMatches, 75);
  });
}
