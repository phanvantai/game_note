import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';

import '../league_detail/league_detail_page.dart';
import 'add_tournament_button.dart';
import 'bloc/league_list_bloc.dart';
import 'league_list_body.dart';

class LeagueListView extends StatelessWidget {
  const LeagueListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Giải đấu'),
      ),
      body: SafeArea(
        child: BlocConsumer<LeagueListBloc, LeagueListState>(
          listener: (context, state) {
            if (state.newLeague != null) {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      LeagueDetailPage(model: state.newLeague!)));
              context.read<LeagueListBloc>().add(LeagueListStarted());
            }
          },
          builder: (context, state) {
            switch (state.status) {
              case LeagueListStatus.error:
                return const AppEmptyState(
                  icon: Icons.error_outline,
                  title: 'Đã xảy ra lỗi',
                  subtitle: 'Vui lòng thử lại sau',
                );
              case LeagueListStatus.loading:
                return Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.secondary,
                  ),
                );
              case LeagueListStatus.loaded:
                if (state.leagues.isEmpty) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 8, right: 8),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            onPressed: () => context
                                .read<LeagueListBloc>()
                                .add(LeagueListStarted()),
                            icon: Icon(
                              Icons.refresh,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                      const Expanded(
                        child: AppEmptyState(
                          icon: Icons.emoji_events_outlined,
                          title: 'Chưa có giải đấu nào được tạo.',
                          subtitle:
                              'Bấm nút + bên dưới để tạo một giải đấu',
                        ),
                      ),
                    ],
                  );
                } else {
                  return const LeagueListBody();
                }
            }
          },
        ),
      ),
      floatingActionButton: const AddTournamentButton(),
    );
  }
}
