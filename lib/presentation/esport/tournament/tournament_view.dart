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
          child: Column(
            children: [
              if (state.viewStatus == ViewStatus.loading)
                const LinearProgressIndicator(),
              ExpansionTile(
                title: const Text('Giải đấu của bạn'),
                backgroundColor: Colors.green[100],
                collapsedBackgroundColor: Colors.green[100],
                shape: Border.all(color: Colors.transparent),
                initiallyExpanded: true,
                maintainState: true,
                children: [
                  if (state.userLeagues.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 60, vertical: 8),
                      child: Center(
                        child: Column(
                          children: [
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
                    ...state.userLeagues.map(
                      (league) => TournamentItem(
                        league: league,
                        onTap: () async {
                          final _ = await Navigator.of(context).pushNamed(
                            Routing.tournamentDetail,
                            arguments: league,
                          );
                          // ignore: use_build_context_synchronously
                          BlocProvider.of<TournamentBloc>(context)
                              .add(GetTournaments());
                        },
                      ),
                    ),
                  const SizedBox(height: 4),
                ],
              ),
              ExpansionTile(
                backgroundColor: Colors.cyan[100],
                collapsedBackgroundColor: Colors.cyan[100],
                shape: Border.all(color: Colors.transparent),
                title: const Text('Giải đấu khác'),
                initiallyExpanded: true,
                showTrailingIcon: false,
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.cyan[100],
                  ),
                  child: state.otherLeagues.isEmpty
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
                              final _ = await Navigator.of(context).pushNamed(
                                Routing.tournamentDetail,
                                arguments: state.otherLeagues[index],
                              );
                              // ignore: use_build_context_synchronously
                              BlocProvider.of<GroupBloc>(context)
                                  .add(GetEsportGroups());
                            },
                          ),
                          itemCount: state.otherLeagues.length,
                        ),
                ),
              )
            ],
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
