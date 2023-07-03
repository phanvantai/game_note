import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:game_note/core/constants/constants.dart';

import '../models/personal_statistic.dart';
import 'legends_list_widget.dart';

class MultiStatistic extends StatelessWidget {
  final List<PersonalStatistic> statistics;
  const MultiStatistic({Key? key, required this.statistics}) : super(key: key);

  static const Color colorChampion = Colors.orange;
  static const Color colorRunnerUp = Colors.green;
  final Color colorPointPerMatch = Colors.red;

  final double widthChampion = 16;
  final double widthRunnerUp = 12;

  @override
  Widget build(BuildContext context) {
    List<BarChartGroupData> rawBarGroups;
    List<BarChartGroupData> showingBarGroups;
    statistics.sort(
      (a, b) => b.percentWinLeague.compareTo(a.percentWinLeague),
    );

    final items = statistics
        .mapIndexed((index, e) =>
            makeGroupData(index, e.percentWinLeague, e.percentRunnerUpLeague))
        .toList();

    rawBarGroups = items;

    showingBarGroups = rawBarGroups;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: kDefaultPadding),
        LegendsListWidget(
          legends: [
            Legend('Tỉ lệ vô địch', colorChampion),
            Legend('Tỉ lệ á quân', colorRunnerUp),
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
                      c.toY.toStringAsFixed(2), const TextStyle()),
                ),
              ),
              titlesData: titlesData,
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

  FlTitlesData get titlesData => FlTitlesData(
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
      );

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
          width: widthChampion,
        ),
        BarChartRodData(
          toY: y2,
          color: colorRunnerUp,
          width: widthRunnerUp,
        ),
      ],
    );
  }
}
