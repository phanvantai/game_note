import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../injection_container.dart';
import '../../domain/entities/league_model.dart';
import 'bloc/league_detail_bloc.dart';
import 'league_detail_view.dart';

class LeagueDetailPage extends StatelessWidget {
  final LeagueModel model;
  const LeagueDetailPage({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LeagueDetailBloc>()..add(LoadLeagueEvent(model.id!)),
      child: const LeagueDetailView(),
    );
  }
}
