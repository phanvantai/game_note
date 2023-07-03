import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:game_note/core/constants/constants.dart';

import '../models/personal_statistic.dart';

class MultiStatistic extends StatelessWidget {
  final List<PersonalStatistic> statistics;
  const MultiStatistic({Key? key, required this.statistics}) : super(key: key);

  static const Color colorChampion = Colors.orange;
  static const Color colorRunnerUp = Colors.green;

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> rawBarGroups;
    List<BarChartGroupData> showingBarGroups;
    statistics.sort(
      (a, b) => b.percentWinLeague.compareTo(a.percentWinLeague),
    );

    final items = statistics
        .mapIndexed((index, e) => makeGroupData(index,
            e.percentWinLeague.toDouble(), e.percentRunnerUpLeague.toDouble()))
        .toList();

    rawBarGroups = items;

    showingBarGroups = rawBarGroups;
    return Column(
      children: [
        const SizedBox(height: kDefaultPadding),
        Row(
          children: [
            const Expanded(flex: 1, child: Text('Tỉ lệ vô địch:')),
            Flexible(
              flex: 3,
              child: Container(
                color: colorChampion,
                width: 16,
                height: 16,
              ),
            )
          ],
        ),
        Row(
          children: [
            const Expanded(flex: 1, child: Text('Tỉ lệ á quân:')),
            Flexible(
              flex: 3,
              child: Container(
                color: colorRunnerUp,
                width: 16,
                height: 16,
              ),
            )
          ],
        ),
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: 55,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Colors.grey,
                  getTooltipItem: (a, b, c, d) => BarTooltipItem(
                      c.toY.toStringAsFixed(0), const TextStyle()),
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: bottomTitles,
                    reservedSize: 42,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: 1,
                    getTitlesWidget: leftTitles,
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: false,
              ),
              barGroups: showingBarGroups,
              gridData: const FlGridData(show: false),
            ),
          ),
        ),
      ],
    );
  }

  Widget leftTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff7589a2),
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text;
    if (value == 0) {
      text = '0%';
    } else if (value == 10) {
      text = '10%';
    } else if (value == 20) {
      text = '20%';
    } else if (value == 30) {
      text = '30%';
    } else if (value == 40) {
      text = '40%';
    } else if (value == 50) {
      text = '50%';
    } else {
      return Container();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 0,
      child: FittedBox(
        child: Text(text, style: style),
      ),
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    final Widget text = Text(
      statistics[value.toInt()].playerModel.fullname,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16, //margin top
      child: text,
    );
  }

  BarChartGroupData makeGroupData(int x, double y1, double y2) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(
          toY: y1,
          color: colorChampion,
          width: 12,
        ),
        BarChartRodData(
          toY: y2,
          color: colorRunnerUp,
          width: 6,
        ),
      ],
    );
  }
}
