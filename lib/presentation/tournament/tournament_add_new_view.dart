import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/components/select_player_view.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_state.dart';

class TournamentAddNewView extends StatelessWidget {
  const TournamentAddNewView({Key? key}) : super(key: key);

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
          backgroundColor: Colors.black,
        ),
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SelectPlayerView(onSelectDone: (players) {
                  print('abcdef ${players.length}');
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
