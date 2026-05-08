import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/routing.dart';

import 'bloc/tournament_detail_bloc.dart';
import 'tournament_detail_view.dart';

class TournamentDetailPage extends StatelessWidget {
  final String leagueId;
  const TournamentDetailPage({super.key, required this.leagueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TournamentDetailBloc(getIt())..add(GetLeague(leagueId)),
      child: BlocListener<TournamentDetailBloc, TournamentDetailState>(
        listener: (context, state) {
          if (state.errorMessage.isNotEmpty) {
            showToast(state.errorMessage);
          }
          if (state.league != null && !state.league!.isActive) {
            showToast('Giải đấu đã kết thúc');
            _safeLeave(context);
            return;
          }
          if (state.errorMessage == 'Không tìm thấy giải đấu') {
            _safeLeave(context);
            return;
          }
        },
        child: const TournamentDetailView(),
      ),
    );
  }
}

void _safeLeave(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(Routing.app);
  }
}
