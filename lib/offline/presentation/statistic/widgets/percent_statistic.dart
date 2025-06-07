import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import '../models/personal_statistic.dart';
import 'legends_list_widget.dart';

class PercentStatistic extends StatelessWidget {
  final List<PersonalStatistic> statistics;
  const PercentStatistic({Key? key, required this.statistics})
      : super(key: key);

  static const Color colorWins = Colors.green;
  static const Color colorDraws = Colors.grey;
  static const Color colorLost = Colors.red;

  final betweenSpace = 0.0;
  final double columnWidth = 20;

  @override
  Widget build(BuildContext context) {
    statistics.sort(
      (a, b) => b.percentWin.compareTo(a.percentWin),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LegendsListWidget(
            legends: [
              Legend('Thắng', colorWins),
              Legend('Hoà', colorDraws),
              Legend('Thua', colorLost),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: bottomTitles,
                      reservedSize: 28,
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    // tooltipBgColor: Colors.grey,
                    getTooltipItem: (a, b, c, d) {
                      return BarTooltipItem(
                          '${(c.toY - c.fromY).toStringAsFixed(2)}%',
                          const TextStyle(color: Colors.black));
                    },
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barGroups: statistics.mapIndexed((index, e) {
                  return generateGroupData(
                      index, e.percentWin, e.percentDraw, e.percentLose);
                }).toList(),
                maxY: 100 + betweenSpace * 2,
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 33.33,
                      color: colorWins,
                      strokeWidth: 1,
                      dashArray: [20, 4],
                    ),
                    HorizontalLine(
                      y: 66.66 + betweenSpace,
                      color: colorDraws,
                      strokeWidth: 1,
                      dashArray: [20, 4],
                    ),
                    HorizontalLine(
                      y: 100 + betweenSpace * 2,
                      color: colorLost,
                      strokeWidth: 1,
                      dashArray: [20, 4],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData generateGroupData(
    int x,
    double win,
    double draw,
    double lose,
  ) {
    return BarChartGroupData(
      x: x,
      groupVertically: true,
      barRods: [
        BarChartRodData(
          fromY: 0,
          toY: win,
          color: colorWins,
          width: columnWidth,
        ),
        BarChartRodData(
          fromY: win + betweenSpace,
          toY: win + betweenSpace + draw,
          color: colorDraws,
          width: columnWidth,
        ),
        BarChartRodData(
          fromY: win + betweenSpace + draw + betweenSpace,
          toY: win + betweenSpace + draw + betweenSpace + lose,
          color: colorLost,
          width: columnWidth,
        ),
      ],
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    const style = TextStyle(fontSize: 14, fontWeight: FontWeight.bold);
    String text = statistics[value.toInt()].playerModel.fullname;
    return SideTitleWidget(
      meta: meta,
      child: Text(text, style: style),
    );
  }
}
