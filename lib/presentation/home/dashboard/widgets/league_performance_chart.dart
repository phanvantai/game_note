import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/league_performance_point.dart';

/// Line chart of the user's PPM (điểm/trận) and GD/trận across the last
/// `windowSize` leagues. Filters out leagues where the user hasn't played
/// any match yet — those carry null metrics and would draw a misleading
/// 0 baseline.
class LeaguePerformanceChart extends StatelessWidget {
  final List<LeaguePerformancePoint> points;
  final int windowSize;

  const LeaguePerformanceChart({
    super.key,
    required this.points,
    this.windowSize = 5,
  });

  @override
  Widget build(BuildContext context) {
    final played = points
        .where((p) => p.matchesPlayed > 0 && p.pointsPerMatch != null)
        .toList();
    if (played.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Chưa đủ dữ liệu để vẽ biểu đồ')),
      );
    }

    final start = played.length > windowSize
        ? played.length - windowSize
        : 0;
    final window = played.sublist(start);

    final ppmSpots = <FlSpot>[];
    final gdSpots = <FlSpot>[];
    for (var i = 0; i < window.length; i++) {
      ppmSpots.add(FlSpot(i.toDouble(), window[i].pointsPerMatch!));
      final gd = window[i].goalDifferencePerMatch ?? 0;
      gdSpots.add(FlSpot(i.toDouble(), gd));
    }

    final theme = Theme.of(context);
    final ppmColor = theme.colorScheme.primary;
    final gdColor = theme.colorScheme.tertiary;

    final allValues = [...ppmSpots.map((s) => s.y), ...gdSpots.map((s) => s.y)];
    final minY = (allValues.reduce((a, b) => a < b ? a : b) - 0.5).clamp(
      -10.0,
      0.0,
    );
    final maxY = (allValues.reduce((a, b) => a > b ? a : b) + 0.5).clamp(
      3.0,
      30.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Wrap(
            spacing: 16,
            children: [
              _LegendDot(color: ppmColor, label: 'Điểm / trận'),
              _LegendDot(color: gdColor, label: 'Hiệu số / trận'),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: (window.length - 1).toDouble(),
              minY: minY,
              maxY: maxY,
              gridData: FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    interval: 1,
                    getTitlesWidget: (value, _) => Text(
                      value.toStringAsFixed(value % 1 == 0 ? 0 : 1),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      final i = value.round();
                      if (i < 0 || i >= window.length) {
                        return const SizedBox.shrink();
                      }
                      final name = window[i].leagueName;
                      final short = name.length > 8
                          ? '${name.substring(0, 7)}…'
                          : name;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          short,
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (spots) {
                    // fl_chart fires this with one spot per line for the
                    // touched X. Render the league header (name + W/D/L)
                    // only on the first spot; the second spot just shows
                    // its own metric line. Avoids the duplicated header.
                    final base =
                        theme.textTheme.bodySmall ?? const TextStyle();
                    final headerStyle =
                        base.copyWith(fontWeight: FontWeight.w700);
                    return [
                      for (var i = 0; i < spots.length; i++)
                        _tooltipFor(
                          spots[i],
                          window,
                          showHeader: i == 0,
                          headerStyle: headerStyle,
                          baseStyle: base,
                        ),
                    ];
                  },
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: ppmSpots,
                  color: ppmColor,
                  barWidth: 3,
                  isCurved: true,
                  dotData: const FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: gdSpots,
                  color: gdColor,
                  barWidth: 2,
                  isCurved: true,
                  dashArray: const [6, 4],
                  dotData: const FlDotData(show: true),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

LineTooltipItem _tooltipFor(
  LineBarSpot spot,
  List<LeaguePerformancePoint> window, {
  required bool showHeader,
  required TextStyle headerStyle,
  required TextStyle baseStyle,
}) {
  final p = window[spot.x.toInt()];
  final isPpm = spot.barIndex == 0;
  final label = isPpm ? 'PPM' : 'GD/M';
  final value = spot.y.toStringAsFixed(2);
  if (showHeader) {
    return LineTooltipItem(
      '${p.leagueName}  (W/D/L ${p.wins}/${p.draws}/${p.losses})\n',
      headerStyle,
      children: [TextSpan(text: '$label  $value', style: baseStyle)],
    );
  }
  return LineTooltipItem('$label  $value', baseStyle);
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
