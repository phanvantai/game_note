import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/offline/presentation/components/select_player_view.dart';

import 'bloc/league_detail_bloc.dart';
import 'components/matches_view.dart';
import 'components/table_view.dart';
import 'league_detail_floating_button.dart';

class LeagueDetailView extends StatelessWidget {
  const LeagueDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LeagueDetailBloc, LeagueDetailState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(state.model?.name ?? ''),
            backgroundColor: Colors.white70,
            actions: [
              if (state.status.isAddingPlayer &&
                  state.enableConfirmSelectPlayers)
                IconButton(
                  onPressed: () {
                    BlocProvider.of<LeagueDetailBloc>(context)
                        .add(ConfirmPlayersInLeague());
                  },
                  icon: const Icon(Icons.done),
                ),
            ],
          ),
          body: SafeArea(
            child: _leagueDetail(context, state),
            bottom: false,
          ),
          floatingActionButton: state.status.needFloatButton
              ? const LeagueDetailFloatingButton()
              : null,
        );
      },
    );
  }

  _leagueDetail(BuildContext context, LeagueDetailState state) {
    if (state.status.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Giải đấu chưa được thiết lập.\nBấm nút + bên dưới để thêm người chơi và bắt đầu giải đấu',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (state.status.isAddingPlayer) {
      return SelectPlayerView(
        enableSection: (players, enable) =>
            BlocProvider.of<LeagueDetailBloc>(context)
                .add(AddPlayersToLeague(players)),
      );
    }
    if (state.status.isError) {
      return const Text('error league ');
    }
    if (state.status.isLoaded || state.status.isUpdating) {
      return GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: const SafeArea(
          bottom: false,
          child: Column(
            children: [
              TableView(),
              SizedBox(height: 12),
              Expanded(child: MatchesView()),
            ],
          ),
        ),
      );
    }
    if (state.status.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return const SizedBox.shrink();
  }
}
