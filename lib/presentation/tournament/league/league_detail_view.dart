import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/domain/entities/league_model.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/components/select_player_view.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_bloc.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_event.dart';
import 'package:game_note/presentation/tournament/league/bloc/league_detail_state.dart';
import 'package:game_note/presentation/tournament/league/components/matches_view.dart';
import 'package:game_note/presentation/tournament/league/components/table_view.dart';

class LeagueDetailView extends StatelessWidget {
  final LeagueModel model;
  const LeagueDetailView({Key? key, required this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LeagueDetailBloc>()..add(LoadLeagueEvent(model.id!)),
      child: BlocBuilder<LeagueDetailBloc, LeagueDetailState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              leading: BackButton(
                onPressed: () => BlocProvider.of<TournamentBloc>(context)
                    .add(CloseLeagueDetailEvent()),
              ),
              title: Text(state.model?.name ?? ''),
              backgroundColor: Colors.black,
              actions: [
                if (state.status.isAddingPlayer &&
                    state.enableConfirmSelectPlayers)
                  IconButton(
                    onPressed: () {
                      BlocProvider.of<LeagueDetailBloc>(context)
                          .add(ConfirmPlayersInLeague());
                    },
                    icon: const Icon(Icons.done),
                  ),
              ],
            ),
            body: SafeArea(child: _leagueDetail(context, state)),
            floatingActionButton: _floatingButton(context, state),
          );
        },
      ),
    );
  }

  Widget? _floatingButton(BuildContext context, LeagueDetailState state) {
    if (state.status.isEmpty) {
      return FloatingActionButton(
        onPressed: () {
          BlocProvider.of<LeagueDetailBloc>(context).add(AddPlayersStarted());
        },
        tooltip: 'Add Players',
        child: const Icon(Icons.add),
      );
    }
    if (state.status.isLoaded || state.status.isUpdating) {
      return FloatingActionButton(
        onPressed: () {
          BlocProvider.of<LeagueDetailBloc>(context).add(AddNewRounds());
        },
        tooltip: 'Add New Round',
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  _leagueDetail(BuildContext context, LeagueDetailState state) {
    if (state.status.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'The league is not configure. Click plus button below to add players and start the league.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (state.status.isAddingPlayer) {
      return SelectPlayerView(
        enableSection: (players, enable) =>
            BlocProvider.of<LeagueDetailBloc>(context)
                .add(AddPlayersToLeague(players)),
      );
    }
    if (state.status.isError) {
      return const Text('error league ');
    }
    if (state.status.isLoaded || state.status.isUpdating) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: const [
              TableView(),
              SizedBox(height: 12),
              Expanded(child: MatchesView()),
            ],
          ),
        ),
      );
    }
    if (state.status.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return const SizedBox.shrink();
  }
}
