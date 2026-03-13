import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/offline/presentation/statistic/bloc/statistic_bloc.dart';
import 'package:pes_arena/offline/presentation/statistic/statistic_body.dart';

class StatisticView extends StatelessWidget {
  const StatisticView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => StatisticBloc(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Thống kê'),
        ),
        body: const SafeArea(
          child: StatisticBody(),
        ),
      ),
    );
  }
}
