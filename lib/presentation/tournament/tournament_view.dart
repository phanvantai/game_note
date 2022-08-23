import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_state.dart';
import 'package:game_note/presentation/tournament/league/tournament_add_new_view.dart';
import 'package:game_note/presentation/tournament/league_list/tournament_list_view.dart';
import 'package:game_note/presentation/tournament/tournament_error_view.dart';
import 'package:game_note/presentation/tournament/tournament_loading_view.dart';
import 'package:game_note/presentation/tournament/tournament_processing_view.dart';

class TournamentView extends StatefulWidget {
  const TournamentView({Key? key}) : super(key: key);

  @override
  State<TournamentView> createState() => _TournamentViewState();
}

class _TournamentViewState extends State<TournamentView>
    with AutomaticKeepAliveClientMixin<TournamentView> {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocProvider(
      create: (_) => TournamentBloc(getIt())..add(LoadListTournamentEvent()),
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
        } else if (state.status.isTournament ||
            state.status.isUpdatingTournament) {
          return const TournamentProcessingView();
        } else {
          return const SizedBox.shrink();
        }
      }),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
