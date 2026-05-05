import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/presentation/home/dashboard/models/league_performance_point.dart';
import 'package:pes_arena/presentation/home/dashboard/widgets/league_performance_chart.dart';

LeaguePerformancePoint _p({
  required String id,
  required String name,
  int played = 5,
  int wins = 3,
  int draws = 1,
  int losses = 1,
  double? ppm = 2.0,
  double? gd = 0.5,
}) => LeaguePerformancePoint(
  leagueId: id,
  leagueName: name,
  lastPlayedAt: DateTime(2026, 1, 1),
  matchesPlayed: played,
  wins: wins,
  draws: draws,
  losses: losses,
  pointsPerMatch: ppm,
  goalDifferencePerMatch: gd,
);

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('empty / chưa-đấu render placeholder', (tester) async {
    await tester.pumpWidget(_wrap(const LeaguePerformanceChart(points: [])));
    expect(find.text('Chưa đủ dữ liệu để vẽ biểu đồ'), findsOneWidget);
  });

  testWidgets('drop leagues chưa đấu (matchesPlayed=0)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LeaguePerformanceChart(
          points: [
            _p(id: 'l1', name: 'Empty', played: 0, ppm: null, gd: null),
          ],
        ),
      ),
    );
    expect(find.text('Chưa đủ dữ liệu để vẽ biểu đồ'), findsOneWidget);
  });

  testWidgets('render chart với 2 đường + legend', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LeaguePerformanceChart(
          points: [
            _p(id: 'l1', name: 'Cup1'),
            _p(id: 'l2', name: 'Cup2'),
            _p(id: 'l3', name: 'Cup3'),
          ],
        ),
      ),
    );
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Điểm / trận'), findsOneWidget);
    expect(find.text('Hiệu số / trận'), findsOneWidget);
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData.length, 2);
    expect(chart.data.lineBarsData[0].spots.length, 3);
  });

  testWidgets('windowSize cắt còn n giải gần nhất', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LeaguePerformanceChart(
          windowSize: 2,
          points: [
            _p(id: 'l1', name: 'Cup1'),
            _p(id: 'l2', name: 'Cup2'),
            _p(id: 'l3', name: 'Cup3'),
          ],
        ),
      ),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData[0].spots.length, 2);
  });

  testWidgets('tooltip: header chỉ hiện 1 lần (spot đầu) + value mỗi line',
      (tester) async {
    final points = [
      _p(id: 'l1', name: 'Cup', wins: 3, draws: 1, losses: 1, ppm: 2.0, gd: 0.6),
      _p(id: 'l2', name: 'Cup2', wins: 2, draws: 2, losses: 1, ppm: 1.6, gd: 0.2),
    ];
    await tester.pumpWidget(
      _wrap(LeaguePerformanceChart(points: points)),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    final tooltipBuilder =
        chart.data.lineTouchData.touchTooltipData.getTooltipItems;
    final spots = [
      LineBarSpot(chart.data.lineBarsData[0], 0, FlSpot(0, 2.0)),
      LineBarSpot(chart.data.lineBarsData[1], 1, FlSpot(0, 0.6)),
    ];
    final items = tooltipBuilder(spots);
    expect(items.length, 2);
    // First spot: header (league + W/D/L) + PPM value child
    expect(items[0]!.text, contains('Cup'));
    expect(items[0]!.text, contains('W/D/L 3/1/1'));
    expect(items[0]!.children, isNotNull);
    expect(items[0]!.children!.first.toPlainText(), contains('PPM'));
    expect(items[0]!.children!.first.toPlainText(), contains('2.00'));
    // Second spot: only the GD/M value, no header repeat
    expect(items[1]!.text, contains('GD/M'));
    expect(items[1]!.text, contains('0.60'));
    expect(items[1]!.text, isNot(contains('Cup')));
    expect(items[1]!.text, isNot(contains('W/D/L')));
  });

  testWidgets('point có ppm null bị drop khỏi chart', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LeaguePerformanceChart(
          points: [
            _p(id: 'l1', name: 'Cup1'),
            _p(id: 'l2', name: 'Cup2', played: 3, ppm: null, gd: null),
            _p(id: 'l3', name: 'Cup3'),
          ],
        ),
      ),
    );
    final chart = tester.widget<LineChart>(find.byType(LineChart));
    expect(chart.data.lineBarsData[0].spots.length, 2);
  });

  testWidgets('xử lý leagueName quá dài (truncate hiển thị)', (tester) async {
    await tester.pumpWidget(
      _wrap(
        LeaguePerformanceChart(
          points: [
            _p(id: 'l1', name: 'A_very_long_league_name'),
            _p(id: 'l2', name: 'Short'),
          ],
        ),
      ),
    );
    expect(find.byType(LineChart), findsOneWidget);
  });
}
