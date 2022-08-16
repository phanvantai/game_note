import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_state.dart';

class TournamentProcessingView extends StatelessWidget {
  const TournamentProcessingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentBloc, TournamentState>(
      builder: (context, state) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: CloseButton(
            onPressed: () {
              BlocProvider.of<TournamentBloc>(context)
                  .add(CloseToLastStateEvent());
            },
          ),
        ),
        body: const SafeArea(
          child: Text('tournament processing'),
        ),
      ),
    );
  }
}
