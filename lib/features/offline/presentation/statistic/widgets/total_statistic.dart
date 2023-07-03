import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:game_note/features/offline/presentation/statistic/models/personal_statistic.dart';

import 'legends_list_widget.dart';

class TotalStatistic extends StatelessWidget {
  final List<PersonalStatistic> statistics;
  const TotalStatistic({
    Key? key,
    required this.statistics,
  }) : super(key: key);

  final Color colorPointPerMatch = Colors.deepOrange;
  final Color colorGDPerMatch = Colors.greenAccent;

  @override
  Widget build(BuildContext context) {
    // calcualate
    // poit permatch
    statistics.sort(
      (a, b) => b.pointPerMatch.compareTo(a.pointPerMatch),
    );
    return Column(
      children: [
        const SizedBox(height: 16),
        LegendsListWidget(
          legends: [
            Legend('Điểm TB', colorPointPerMatch),
            Legend('Hiệu số bàn thắng TB', colorGDPerMatch),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: BarChart(
            BarChartData(
              barTouchData: barTouchData,
              titlesData: titlesData,
              borderData: FlBorderData(show: false),
              barGroups: barGroups,
              gridData: const FlGridData(show: false),
              alignment: BarChartAlignment.spaceAround,
              maxY: statistics.map((e) => e.pointPerMatch).reduce(max) + 0.15,
              minY: statistics.map((e) => e.goalDifferentPerMatch).reduce(min) -
                  0.15,
            ),
          ),
        )
      ],
    );
  }

  BarTouchData get barTouchData => BarTouchData(
        enabled: false,
        touchTooltipData: BarTouchTooltipData(
          tooltipBgColor: Colors.transparent,
          tooltipPadding: EdgeInsets.zero,
          tooltipMargin: 8,
          getTooltipItem: (
            BarChartGroupData group,
            int groupIndex,
            BarChartRodData rod,
            int rodIndex,
          ) {
            return BarTooltipItem(
              rod.toY.toStringAsFixed(2),
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      );
  Widget getTitles(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    String text = statistics[value.toInt()].playerModel.fullname;

    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 4,
      child: Text(text, style: style),
    );
  }

  FlTitlesData get titlesData => FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: getTitles,
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      );

  List<BarChartGroupData> get barGroups => statistics
      .mapIndexed((index, e) => BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: e.pointPerMatch,
                color: colorPointPerMatch,
              ),
              BarChartRodData(
                toY: e.goalDifferentPerMatch,
                color: Colors.greenAccent,
              ),
            ],
            showingTooltipIndicators: [0, 1],
          ))
      .toList();
}
