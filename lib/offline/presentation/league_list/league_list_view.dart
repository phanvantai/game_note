import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/l10n/l10n.dart';

import '../league_detail/league_detail_page.dart';
import 'add_tournament_button.dart';
import 'bloc/league_list_bloc.dart';
import 'league_list_body.dart';

class LeagueListView extends StatelessWidget {
  const LeagueListView({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.offlineLeagueTitle)),
      body: SafeArea(
        child: BlocConsumer<LeagueListBloc, LeagueListState>(
          listener: (context, state) {
            if (state.newLeague != null) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      LeagueDetailPage(model: state.newLeague!),
                ),
              );
              context.read<LeagueListBloc>().add(LeagueListStarted());
            }
          },
          builder: (context, state) {
            switch (state.status) {
              case LeagueListStatus.error:
                return AppEmptyState(
                  icon: Icons.error_outline,
                  title: l10n.commonErrorTitle,
                  subtitle: l10n.commonRetryLater,
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
                            onPressed: () => context.read<LeagueListBloc>().add(
                              LeagueListStarted(),
                            ),
                            icon: Icon(
                              Icons.refresh,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: AppEmptyState(
                          icon: Icons.emoji_events_outlined,
                          title: l10n.offlineNoLeaguesTitle,
                          subtitle: l10n.offlineNoLeaguesSubtitle,
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
