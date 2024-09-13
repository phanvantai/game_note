import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/presentation/esport/tournament/bloc/tournament_bloc.dart';

import '../groups/bloc/group_bloc.dart';
import 'create_esport_league_dialog.dart';

class TournamentView extends StatelessWidget {
  const TournamentView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TournamentBloc, TournamentState>(
      builder: (context, state) => Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              state.leagues.isEmpty
                  ? const Center(child: Text('Không có giải đấu nào'))
                  : ListView.builder(
                      itemCount: state.leagues.length,
                      itemBuilder: (context, index) {
                        final league = state.leagues[index];
                        return ListTile(
                          title: Text(league.name),
                          subtitle: Text(league.description),
                        );
                      },
                    ),
              if (state.viewStatus.isLoading) const LinearProgressIndicator(),
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
