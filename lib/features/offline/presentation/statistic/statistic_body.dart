import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/features/offline/presentation/statistic/bloc/statistic_bloc.dart';

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
        return ListView.builder(
          itemCount: state.listStatistic.length,
          itemBuilder: (context, index) => Column(
            children: [
              Text(state.listStatistic[index].playerModel.fullname),
              Text('Tỉ lệ thắng ${state.listStatistic[index].percentWin}'),
              Text('Tỉ lệ hòa ${state.listStatistic[index].percentDraw}'),
              Text('Tỉ lệ thua ${state.listStatistic[index].percentLose}'),
              Text(
                  'Điểm trung bình mỗi trận ${state.listStatistic[index].pointPerMatch}'),
              Text(
                  '${state.listStatistic[index].totalWinsDrawLose} / ${state.listStatistic[index].countMatches}'),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }
}
