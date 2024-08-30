import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/offline/presentation/league_list/league_list_view.dart';

import '../league_list/bloc/league_list_bloc.dart';

class LeaguePage extends StatelessWidget {
  const LeaguePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LeagueListBloc(
          getLeagues: getIt(), deleteLeague: getIt(), createLeague: getIt())
        ..add(LeagueListStarted()),
      child: const LeagueListView(),
    );
  }
}
