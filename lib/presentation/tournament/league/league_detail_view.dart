import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/domain/entities/league_model.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_bloc.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_event.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_state.dart';
import 'package:game_note/presentation/tournament/league/tournament_add_new_view.dart';

class LeagueDetailView extends StatelessWidget {
  final LeagueModel model;
  const LeagueDetailView({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          LeagueDetailBloc(getLeague: getIt())..add(LoadLeagueEvent(model.id!)),
      child: BlocBuilder<LeagueDetailBloc, LeagueDetailState>(
        builder: (context, state) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            leading: BackButton(
              onPressed: () => BlocProvider.of<TournamentBloc>(context)
                  .add(CloseLeagueDetailEvent()),
            ),
            title: Text(state.model?.name ?? ''),
            backgroundColor: Colors.black,
          ),
          body: SafeArea(child: _leagueDetail(state)),
        ),
      ),
    );
  }

  _leagueDetail(LeagueDetailState state) {
    if (state.status.isEmpty) {
      return const Text('data');
    }
    if (state.status.isAddingPlayer) {
      return const TournamentAddNewView();
    }
    if (state.status.isError) {
      return const Text('error league ');
    }
    if (state.status.isLoaded || state.status.isUpdating) {
      return const Text('loaded');
    }
    if (state.status.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return const SizedBox.shrink();
  }
}
