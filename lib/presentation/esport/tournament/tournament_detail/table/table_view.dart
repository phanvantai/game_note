import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:game_note/widgets/gn_circle_avatar.dart';
import 'package:game_note/widgets/gn_floating_button.dart';

import '../../../../../firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import '../../../../../injection_container.dart';
import '../../../../users/bloc/user_bloc.dart';
import '../../../../users/user_item.dart';
import 'widgets/table_fixed_column_header.dart';
import 'widgets/table_scrollable_column_header.dart';
import 'widgets/table_scrollable_column_item.dart';

class EsportTableView extends StatelessWidget {
  const EsportTableView({Key? key}) : super(key: key);

  static const double tableRowHeight = 44.0;
  static const double tableIconColumnWidth = 44.0;
  static const double tableNameColumnWidth = 120.0;
  static const double tableStatsColumnWidth = 40.0;

  static const TextStyle tableStatsTextStyle =
      TextStyle(fontWeight: FontWeight.bold);

  static const Color tableBackgroundColor = Colors.transparent;

  static const BoxDecoration tableItemDecor = BoxDecoration(
    color: tableBackgroundColor,
    border: Border(bottom: BorderSide(color: Colors.grey, width: 1)),
  );
  static const BoxDecoration tableHeaderDecor = BoxDecoration(
    color: tableBackgroundColor,
    border: Border(
      bottom: BorderSide(color: Colors.grey, width: 1),
      top: BorderSide(color: Colors.grey, width: 1),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentDetailBloc, TournamentDetailState>(
      builder: (context, state) {
        return Stack(
          children: [
            // table view
            if (state.participants.isEmpty)
              const Center(
                child: Text('Chưa có người chơi nào'),
              )
            else
              SingleChildScrollView(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildFixColumns(context, state.participants),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildScrollableColumns(
                              context, state.participants),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            // if current user in group of league
            if (state.currentUserIsMember)
              // add participant button
              Positioned(
                right: 16.0,
                bottom: 16.0,
                child: GNFloatingButton(
                  label: 'Thêm người chơi',
                  onPressed: () {
                    _addParticipant(context, state);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  _addParticipant(BuildContext context, TournamentDetailState state) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final userBloc = getIt<UserBloc>();
        return BlocBuilder<UserBloc, UserState>(
          bloc: userBloc
            ..add(SearchUserByEsportGroup(state.league.groupId, '')),
          builder: (userContext, userState) => AlertDialog(
            title: const Text('Thêm thành viên'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Tìm kiếm',
                  ),
                  onChanged: (value) {
                    userBloc.add(
                        SearchUserByEsportGroup(state.league.groupId, value));
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 250,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: userState.users.length,
                    itemBuilder: (ctx, index) {
                      final user = userState.users[index];
                      // ignore existing participants stats
                      if (state.participants
                          .map((e) => e.userId)
                          .contains(user.id)) {
                        return const SizedBox.shrink();
                      }
                      return UserItem(
                        user: user,
                        onTap: () {
                          // add participant to league
                          BlocProvider.of<TournamentDetailBloc>(context).add(
                            AddParticipant(state.league.id, user.id),
                          );
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Hủy'),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildFixColumns(
      BuildContext context, List<GNEsportLeagueStat> listStats) {
    return List.generate(
      listStats.length + 1,
      (index) {
        if (index == 0) {
          return const TableFixedColumnHeader(
            tableIconColumnWidth: tableIconColumnWidth,
            tableRowHeight: tableRowHeight,
          );
        }
        final stats = listStats[index - 1];
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ranking
            Container(
              decoration: tableItemDecor,
              alignment: Alignment.center,
              width: tableIconColumnWidth - 4,
              height: tableRowHeight,
              child: Text(
                '$index',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Container(
              alignment: Alignment.center,
              width: tableIconColumnWidth + 4,
              height: tableRowHeight,
              decoration: tableItemDecor,
              child: GNCircleAvatar(
                size: 32,
                photoUrl: stats.user?.photoUrl,
              ),
            )
          ],
        );
      },
    );
  }

  List<Widget> _buildScrollableColumns(
      BuildContext context, List<GNEsportLeagueStat> listStats) {
    return List.generate(
      listStats.length + 1,
      (index) {
        if (index == 0) {
          return const TableScrollableColumnHeader(
            tableHeaderDecor: tableHeaderDecor,
            tableRowHeight: tableRowHeight,
            tableNameColumnWidth: tableNameColumnWidth,
            tableStatsColumnWidth: tableStatsColumnWidth,
            tableStatsTextStyle: tableStatsTextStyle,
          );
        }
        final stats = listStats[index - 1];
        return TableScrollableColumnItem(
          tableItemDecor: tableItemDecor,
          tableRowHeight: tableRowHeight,
          tableNameColumnWidth: tableNameColumnWidth,
          stats: stats,
          tableStatsColumnWidth: tableStatsColumnWidth,
          tableStatsTextStyle: tableStatsTextStyle,
        );
      },
    );
  }
}
