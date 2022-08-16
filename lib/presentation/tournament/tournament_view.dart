import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_state.dart';
import 'package:game_note/presentation/tournament/tournament_add_new_view.dart';
import 'package:game_note/presentation/tournament/tournament_list_view.dart';
import 'package:game_note/presentation/tournament/tournament_error_view.dart';
import 'package:game_note/presentation/tournament/tournament_loading_view.dart';

class TournamentView extends StatelessWidget {
  const TournamentView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TournamentBloc()..add(LoadListTournamentEvent()),
      child: BlocBuilder<TournamentBloc, TournamentState>(
          builder: (context, state) {
        if (state.status.isLoading) {
          return const TournamentLoadingView();
        } else if (state.status.isError) {
          return const TournamentErrorView();
        } else if (state.status.isAddPlayer) {
          return const TournamentAddNewView();
        } else if (state.status.isList) {
          return const TournamentListView();
        } else {
          return const SizedBox.shrink();
        }
      }),
    );
  }
}
