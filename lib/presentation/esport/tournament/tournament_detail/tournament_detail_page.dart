import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../firebase/firestore/esport/league/gn_esport_league.dart';
import 'bloc/tournament_detail_bloc.dart';
import 'tournament_detail_view.dart';

class TournamentDetailPage extends StatelessWidget {
  const TournamentDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final GNEsportLeague league =
        ModalRoute.of(context)!.settings.arguments as GNEsportLeague;
    return BlocProvider(
      create: (_) =>
          TournamentDetailBloc(league)..add(GetParticipantStats(league.id)),
      child: const TournamentDetailView(),
    );
  }
}
