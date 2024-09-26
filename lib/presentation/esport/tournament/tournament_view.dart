import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/presentation/esport/tournament/bloc/tournament_bloc.dart';
import 'package:game_note/presentation/esport/tournament/tournament_item.dart';

import '../../../routing.dart';
import '../groups/bloc/group_bloc.dart';
import 'create_esport_league_dialog.dart';

class TournamentView extends StatelessWidget {
  const TournamentView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emptyImage = Image.asset(
      'assets/images/empty.png',
      height: 44,
    );
    return BlocConsumer<TournamentBloc, TournamentState>(
      builder: (context, state) => Scaffold(
        body: SafeArea(
          child: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                if (state.viewStatus == ViewStatus.loading)
                  const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: TabBar(
                    // dividerHeight: 0,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: Colors.green[100],
                    ),
                    indicatorPadding: const EdgeInsets.symmetric(
                        horizontal: -12, vertical: 4),
                    indicatorWeight: 0,
                    dividerColor: Colors.transparent,
                    tabAlignment: TabAlignment.start,
                    isScrollable: true,
                    tabs: const [
                      Tab(text: 'Giải đấu của bạn'),
                      Tab(text: 'Giải đấu khác'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      if (state.userLeagues.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 60, vertical: 8),
                          child: Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 100),
                                emptyImage,
                                const Text(
                                  'Không có giải đấu nào.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          itemBuilder: (context, index) => TournamentItem(
                            league: state.userLeagues[index],
                            onTap: () async {
                              final _ = await Navigator.of(context).pushNamed(
                                Routing.tournamentDetail,
                                arguments: state.userLeagues[index],
                              );
                              // ignore: use_build_context_synchronously
                              BlocProvider.of<GroupBloc>(context)
                                  .add(GetEsportGroups());
                            },
                          ),
                          itemCount: state.userLeagues.length,
                        ),
                      state.otherLeagues.isEmpty
                          ? Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 100),
                                  emptyImage,
                                  const Text(
                                    'Không có nhóm nào',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemBuilder: (context, index) => TournamentItem(
                                league: state.otherLeagues[index],
                                onTap: () async {
                                  final _ =
                                      await Navigator.of(context).pushNamed(
                                    Routing.tournamentDetail,
                                    arguments: state.otherLeagues[index],
                                  );
                                  // ignore: use_build_context_synchronously
                                  BlocProvider.of<GroupBloc>(context)
                                      .add(GetEsportGroups());
                                },
                              ),
                              itemCount: state.otherLeagues.length,
                            )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        floatingActionButton: ElevatedButton.icon(
          onPressed: () {
            // show dialog to create tournament
            final groups = context.read<GroupBloc>().state.userGroups;
            if (groups.isEmpty) {
              showToast('Bạn chưa tham gia nhóm nào. Hãy tham gia nhóm trước');
              return;
            }
            showDialog(
              context: context,
              builder: (ctx) {
                return CreateEsportLeagueDialog(
                  groups: groups,
                  onAddLeague:
                      (name, groupId, startDate, endDate, description) {
                    context.read<TournamentBloc>().add(
                          AddTournament(
                            name: name,
                            groupId: groupId,
                            startDate: startDate,
                            endDate: endDate,
                            description: description,
                          ),
                        );
                    Navigator.of(ctx).pop();
                  },
                );
              },
            );
          },
          label: const Text('Tạo giải đấu'),
          icon: const Icon(Icons.add),
          style: ButtonStyle(
            elevation: WidgetStateProperty.all(0),
            backgroundColor: WidgetStateProperty.all(Colors.red[100]),
          ),
        ),
      ),
      listener: (context, state) {
        if (state.errorMessage.isNotEmpty) {
          showToast(state.errorMessage);
        }
      },
    );
  }
}
