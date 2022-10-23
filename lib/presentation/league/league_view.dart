import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/league/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/league/bloc/tournament_event.dart';
import 'package:game_note/presentation/league/bloc/tournament_state.dart';
import 'package:game_note/presentation/league/league/league_detail_view.dart';
import 'package:game_note/presentation/league/league_list/league_list_view.dart';
import 'package:game_note/presentation/league/components/tournament_error_view.dart';
import 'package:game_note/presentation/league/components/tournament_loading_view.dart';

import 'league/bloc/league_detail_bloc.dart';
import 'league/bloc/league_detail_event.dart';
import 'league_list/bloc/league_list_bloc.dart';
import 'league_list/bloc/league_list_event.dart';

class LeagueView extends StatefulWidget {
  const LeagueView({Key? key}) : super(key: key);

  @override
  State<LeagueView> createState() => _LeagueViewState();
}

class _LeagueViewState extends State<LeagueView>
    with AutomaticKeepAliveClientMixin<LeagueView> {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MultiBlocProvider(
      providers: [
        BlocProvider(
            create: (_) => TournamentBloc(getIt())..add(LoadListLeagueEvent())),
        BlocProvider(create: (_) => LeagueListBloc(getLeagues: getIt())),
        BlocProvider(create: (_) => getIt<LeagueDetailBloc>())
      ],
      child: BlocListener<TournamentBloc, TournamentState>(
        listener: (context, state) {
          if (state.status.isList) {
            context.read<LeagueListBloc>().add(LeagueListStarted());
          }
          if (state.status.isLeague) {
            context
                .read<LeagueDetailBloc>()
                .add(LoadLeagueEvent(state.leagueModel!.id!));
          }
        },
        child: BlocBuilder<TournamentBloc, TournamentState>(
          builder: (context, state) {
            switch (state.status) {
              case TournamentStatus.error:
                return const TournamentErrorView();
              case TournamentStatus.loading:
                return const TournamentLoadingView();
              case TournamentStatus.list:
                return const LeagueListView();
              case TournamentStatus.league:
                return LeagueDetailView(model: state.leagueModel!);
            }
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
