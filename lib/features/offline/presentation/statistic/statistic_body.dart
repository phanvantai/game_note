import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/features/offline/presentation/statistic/bloc/statistic_bloc.dart';
import 'package:game_note/features/offline/presentation/statistic/widgets/total_statistic.dart';

class StatisticBody extends StatefulWidget {
  const StatisticBody({Key? key}) : super(key: key);

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
    return BlocBuilder<StatisticBloc, StatisticState>(
        builder: (context, state) {
      if (state.viewStatus.isLoading) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.white),
        );
      }
      if (state.viewStatus.isSuccess) {
        // poit permatch
        state.listStatistic.sort(
          (a, b) => b.pointPerMatch.compareTo(a.pointPerMatch),
        );
        return TotalStatistic(statistics: state.listStatistic);
      }
      return const SizedBox.shrink();
    });
  }
}
