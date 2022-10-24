import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/domain/entities/match_model.dart';
import 'package:game_note/presentation/components/update_match_dialog.dart';
import 'package:game_note/presentation/league/league_detail/bloc/league_detail_bloc.dart';
import 'package:game_note/presentation/league/league_detail/components/list_rounds_view.dart';

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
              Tab(child: Text('Results')),
            ],
            indicatorColor: Colors.orange,
            indicatorWeight: 4,
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<LeagueDetailBloc, LeagueDetailState>(
              builder: (context, state) => TabBarView(
                children: [
                  ListRoundsView(
                    list: state.model?.rounds ?? [],
                    callback: (match) {
                      _updateMatch(match, context);
                    },
                  ),
                  ListRoundsView(
                    list: state.model?.rounds ?? [],
                    status: true,
                  ),
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
        callback: (match, home, away) async {
          BlocProvider.of<LeagueDetailBloc>(context).add(UpdateMatchEvent(
              matchModel: match, homeScore: home, awayScore: away));
        },
      ),
    );
  }
}
