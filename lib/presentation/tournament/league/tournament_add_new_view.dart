import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/presentation/components/select_player_view.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_state.dart';

class TournamentAddNewView extends StatefulWidget {
  const TournamentAddNewView({Key? key}) : super(key: key);

  @override
  State<TournamentAddNewView> createState() => _TournamentAddNewViewState();
}

class _TournamentAddNewViewState extends State<TournamentAddNewView> {
  List<PlayerModel> players = [];
  bool enable = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentBloc, TournamentState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          leading: CloseButton(
            onPressed: () {
              BlocProvider.of<TournamentBloc>(context)
                  .add(CloseToLastStateEvent());
            },
          ),
          actions: [
            if (enable)
              IconButton(
                onPressed: () {
                  // add list player to bloc
                  BlocProvider.of<TournamentBloc>(context)
                      .add(AddPlayersToTournament(players: players));
                },
                icon: const Icon(Icons.done),
              ),
          ],
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SelectPlayerView(enableSection: (players, enable) {
                  setState(() {
                    this.players = players;
                    this.enable = enable;
                  });
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
