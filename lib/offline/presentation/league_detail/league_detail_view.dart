import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/offline/presentation/components/select_player_view.dart';

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
          appBar: AppBar(
            title: Text(state.model?.name ?? ''),
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
    final colorScheme = Theme.of(context).colorScheme;
    if (state.status.isEmpty) {
      return const AppEmptyState(
        icon: Icons.group_add_outlined,
        title: 'Giải đấu chưa được thiết lập.',
        subtitle: 'Bấm nút + bên dưới để thêm người chơi và bắt đầu giải đấu',
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
      return const AppEmptyState(
        icon: Icons.error_outline,
        title: 'Đã xảy ra lỗi',
        subtitle: 'Không thể tải dữ liệu giải đấu',
      );
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
      return Center(
        child: CircularProgressIndicator(
          color: colorScheme.secondary,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
