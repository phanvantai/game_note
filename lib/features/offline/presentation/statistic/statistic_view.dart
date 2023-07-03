import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/offline/presentation/statistic/bloc/statistic_bloc.dart';
import 'package:game_note/features/offline/presentation/statistic/statistic_body.dart';

class StatisticView extends StatelessWidget {
  const StatisticView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // appBar: AppBar(
      //   title: const Text('Thống kê'),
      //   backgroundColor: Colors.black,
      // ),
      body: BlocProvider(
        create: (_) => StatisticBloc(),
        child: const SafeArea(
          child: StatisticBody(),
        ),
      ),
    );
  }
}
