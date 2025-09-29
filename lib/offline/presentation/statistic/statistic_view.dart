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
        backgroundColor: Colors.white70,
        appBar: AppBar(
          title: const Text('Thống kê'),
          backgroundColor: Colors.white70,
        ),
        body: const SafeArea(
          child: StatisticBody(),
        ),
      ),
    );
  }
}
