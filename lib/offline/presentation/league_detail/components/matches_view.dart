import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/offline/domain/entities/match_model.dart';
import 'package:pes_arena/offline/presentation/components/update_match_dialog.dart';

import '../bloc/league_detail_bloc.dart';
import 'list_rounds_view.dart';

class MatchesView extends StatelessWidget {
  const MatchesView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            indicatorSize: TabBarIndicatorSize.tab,
            tabs: [
              Tab(child: Text(context.l10n.offlineSchedule)),
              Tab(child: Text(context.l10n.offlineResults)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<LeagueDetailBloc, LeagueDetailState>(
              builder: (context, state) => TabBarView(
                children: [
                  ListRoundsView(
                    list: state.model?.rounds ?? [],
                    updateMatchCallback: (match) {
                      _updateMatch(match, context);
                    },
                  ),
                  ListRoundsView(
                    list: state.model?.rounds ?? [],
                    status: true,
                    reUpdateMatchCallback: (p0) {
                      _updateMatch(p0, context);
                    },
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
          BlocProvider.of<LeagueDetailBloc>(context).add(
            UpdateMatchEvent(
              matchModel: match,
              homeScore: home,
              awayScore: away,
            ),
          );
        },
      ),
    );
  }
}
