import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/injection_container.dart';

import 'bloc/tournament_detail_bloc.dart';
import 'tournament_detail_view.dart';

class TournamentDetailPage extends StatelessWidget {
  const TournamentDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String leagueId =
        ModalRoute.of(context)!.settings.arguments as String;
    return BlocProvider(
      create: (_) => TournamentDetailBloc(getIt())..add(GetLeague(leagueId)),
      child: const TournamentDetailView(),
    );
  }
}
