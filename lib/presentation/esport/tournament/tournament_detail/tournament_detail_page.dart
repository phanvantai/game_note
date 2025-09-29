import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/injection_container.dart';

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
      child: BlocListener<TournamentDetailBloc, TournamentDetailState>(
        listener: (context, state) {
          if (state.errorMessage.isNotEmpty) {
            showToast(state.errorMessage);
          }
          if (state.league != null && !state.league!.isActive) {
            showToast('Giải đấu đã kết thúc');
            Navigator.of(context).pop();
            return;
          }
          if (state.errorMessage == 'Không tìm thấy giải đấu') {
            Navigator.of(context).pop();
            return;
          }
        },
        child: const TournamentDetailView(),
      ),
    );
  }
}
