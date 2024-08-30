import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/core/constants/constants.dart';
import 'package:game_note/offline/presentation/statistic/bloc/statistic_bloc.dart';
import 'package:game_note/offline/presentation/statistic/widgets/multi_statistic.dart';
import 'package:game_note/offline/presentation/statistic/widgets/percent_statistic.dart';
import 'package:game_note/offline/presentation/statistic/widgets/total_statistic.dart';

class StatisticBody extends StatefulWidget {
  const StatisticBody({Key? key}) : super(key: key);

  @override
  State<StatisticBody> createState() => _StatisticBodyState();
}

class _StatisticBodyState extends State<StatisticBody> {
  final tabs = const [
    Tab(
      icon: FittedBox(
        child: Text('Điểm/Hiệu số'),
      ),
    ),
    Tab(
      icon: FittedBox(
        child: Text('Vô địch/Á quân'),
      ),
    ),
    Tab(
      icon: FittedBox(
        child: Text('Thắng/Hoà/Thua'),
      ),
    ),
  ];
  @override
  void initState() {
    super.initState();
    context.read<StatisticBloc>().add(GeneratePersonalStatisticEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatisticBloc, StatisticState>(
        builder: (context, state) {
      if (state.viewStatus.isLoading) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
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
              const SizedBox(height: kDefaultPadding)
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }
}
