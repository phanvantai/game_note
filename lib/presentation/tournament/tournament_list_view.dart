import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';

class TournamentListView extends StatelessWidget {
  const TournamentListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: const SafeArea(
        child: Center(child: Text('list tournament')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          BlocProvider.of<TournamentBloc>(context).add(AddNewTournamentEvent());
        },
        tooltip: 'Add New Tournament',
        child: const Icon(Icons.add),
      ),
    );
  }
}
