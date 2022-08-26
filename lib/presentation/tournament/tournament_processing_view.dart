import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/matches_view.dart';
import 'package:game_note/presentation/tournament/league/table_view.dart';

class TournamentProcessingView extends StatelessWidget {
  const TournamentProcessingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            children: const [
              //TableView(),
              SizedBox(height: 12),
              Expanded(child: MatchesView()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          BlocProvider.of<TournamentBloc>(context).add(AddNewRoundEvent());
        },
        tooltip: 'Add New Round',
        child: const Icon(Icons.add),
      ),
    );
  }
}
