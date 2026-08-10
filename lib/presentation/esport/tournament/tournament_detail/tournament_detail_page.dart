import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_repository.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/common/smart_back.dart';

import 'bloc/tournament_detail_bloc.dart';
import 'tournament_detail_view.dart';

class TournamentDetailPage extends StatelessWidget {
  final String leagueId;
  const TournamentDetailPage({super.key, required this.leagueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TournamentDetailBloc(
        getIt<EsportLeagueRepository>(),
        getIt<EsportGroupRepository>(),
      )..add(OpenLeagueDetail(leagueId)),
      child: BlocListener<TournamentDetailBloc, TournamentDetailState>(
        listenWhen: (previous, current) {
          final previousIsTerminal =
              previous.leagueDeleted || previous.league?.isActive == false;
          final currentIsTerminal =
              current.leagueDeleted || current.league?.isActive == false;
          return !previousIsTerminal && currentIsTerminal;
        },
        listener: (context, state) => context.smartBack(),
        child: const TournamentDetailView(),
      ),
    );
  }
}
