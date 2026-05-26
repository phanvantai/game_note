import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/constants/constants.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/offline/presentation/statistic/bloc/statistic_bloc.dart';
import 'package:pes_arena/offline/presentation/statistic/widgets/multi_statistic.dart';
import 'package:pes_arena/offline/presentation/statistic/widgets/percent_statistic.dart';
import 'package:pes_arena/offline/presentation/statistic/widgets/total_statistic.dart';

class StatisticBody extends StatefulWidget {
  const StatisticBody({super.key});

  @override
  State<StatisticBody> createState() => _StatisticBodyState();
}

class _StatisticBodyState extends State<StatisticBody> {
  @override
  void initState() {
    super.initState();
    context.read<StatisticBloc>().add(GeneratePersonalStatisticEvent());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tabs = [
      Tab(icon: FittedBox(child: Text(context.l10n.offlineStatPointsGoalDiff))),
      Tab(
        icon: FittedBox(child: Text(context.l10n.offlineStatChampionRunnerUp)),
      ),
      Tab(icon: FittedBox(child: Text(context.l10n.offlineStatWinDrawLoss))),
    ];
    return BlocBuilder<StatisticBloc, StatisticState>(
      builder: (context, state) {
        if (state.viewStatus.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: colorScheme.secondary),
          );
        }
        if (state.viewStatus.isSuccess) {
          return DefaultTabController(
            length: tabs.length,
            child: Column(
              children: [
                TabBar(
                  tabs: tabs,
                  dividerHeight: 0,
                  indicatorColor: colorScheme.secondary,
                  labelColor: colorScheme.secondary,
                  unselectedLabelColor: colorScheme.onSurface.withValues(
                    alpha: 0.5,
                  ),
                  indicatorSize: TabBarIndicatorSize.label,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      TotalStatistic(statistics: state.listStatistic),
                      MultiStatistic(statistics: state.listStatistic),
                      PercentStatistic(statistics: state.listStatistic),
                    ],
                  ),
                ),
                const SizedBox(height: kDefaultPadding),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
