import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/constants/constants.dart';

import '../league_detail/league_detail_page.dart';
import 'bloc/league_list_bloc.dart';

class LeagueListBody extends StatelessWidget {
  const LeagueListBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeagueListBloc, LeagueListState>(
      builder: (context, state) => ListView.separated(
        itemCount: state.leagues.length,
        itemBuilder: (context, index) => InkWell(
          onDoubleTap: () {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text('Xoá giải đấu ${state.leagues[index].name}?'),
                actions: [
                  CloseButton(
                      onPressed: () => Navigator.of(dialogContext).pop()),
                  IconButton(
                    onPressed: () {
                      context
                          .read<LeagueListBloc>()
                          .add(DeleteLeagueEvent(state.leagues[index]));
                      Navigator.of(dialogContext).pop();
                    },
                    icon: const Icon(Icons.done),
                  ),
                ],
              ),
            );
          },
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    LeagueDetailPage(model: state.leagues[index])));
          },
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Theme.of(context).primaryColor.withOpacity(0.5),
            ),
            padding: const EdgeInsets.all(kDefaultPadding),
            margin: const EdgeInsets.only(
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
        separatorBuilder: (BuildContext context, int index) {
          return const SizedBox(height: 16);
        },
      ),
    );
  }
}
