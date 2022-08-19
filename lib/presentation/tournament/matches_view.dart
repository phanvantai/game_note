import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/presentation/components/update_match_dialog.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_event.dart';
import 'package:game_note/presentation/tournament/bloc/tournament_state.dart';
import 'package:game_note/presentation/tournament/list_matches_view.dart';

class MatchesView extends StatelessWidget {
  const MatchesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(child: Text('Fixtures')),
              Tab(icon: Text('Results')),
            ],
            indicatorColor: Colors.orange,
            indicatorWeight: 4,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<TournamentBloc, TournamentState>(
              builder: (context, state) => TabBarView(
                children: [
                  ListMatchesView(
                    list: state.matches
                        .where((element) => element.status == false)
                        .toList(),
                    callback: (match) {
                      _updateMatch(match, context);
                    },
                  ),
                  ListMatchesView(
                      list: state.matches
                          .where((element) => element.status == true)
                          .toList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _updateMatch(MatchModel model, BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => UpdateMatchDialog(
        model: model,
        callback: (match, home, away) {
          BlocProvider.of<TournamentBloc>(context)
              .add(UpdateMatchEvent(matchModel: match, home: home, away: away));
        },
      ),
    );
  }
}
