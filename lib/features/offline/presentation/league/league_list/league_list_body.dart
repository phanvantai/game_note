import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/constants/constants.dart';

import '../bloc/tournament_bloc.dart';
import 'bloc/league_list_bloc.dart';

class LeagueListBody extends StatelessWidget {
  const LeagueListBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeagueListBloc, LeagueListState>(
      builder: (context, state) => ListView.builder(
        itemCount: state.leagues.length,
        itemBuilder: (context, index) => InkWell(
          onDoubleTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Xoá giải đấu ${state.leagues[index].name}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Huỷ',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Đồng ý',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
          onTap: () => BlocProvider.of<TournamentBloc>(context)
              .add(SelectLeagueEvent(state.leagues[index])),
          child: Container(
            color: Colors.grey.withOpacity(0.3),
            padding: const EdgeInsets.all(kDefaultPadding),
            margin: const EdgeInsets.only(
              bottom: kDefaultPadding,
              left: kDefaultPadding,
              right: kDefaultPadding,
            ),
            child: Center(
              child: Text(
                state.leagues[index].name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
