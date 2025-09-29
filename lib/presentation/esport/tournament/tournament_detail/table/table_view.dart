import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_detail/bloc/tournament_detail_bloc.dart';
import 'package:pes_arena/widgets/gn_circle_avatar.dart';

import '../../../../../firebase/firestore/esport/league/stats/gn_esport_league_stat.dart';
import 'widgets/table_fixed_column_header.dart';
import 'widgets/table_scrollable_column_header.dart';
import 'widgets/table_scrollable_column_item.dart';

class EsportTableView extends StatelessWidget {
  const EsportTableView({Key? key}) : super(key: key);

  static const double tableRowHeight = 44.0;
  static const double tableIconColumnWidth = 44.0;
  static const double tableNameColumnWidth = 120.0;
  static const double tableStatsColumnWidth = 36.0;

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
        if (state.participants.isEmpty) {
          return const Center(
            child: Text('Chưa có người chơi nào'),
          );
        } else {
          return SingleChildScrollView(
            padding: const EdgeInsets.only(top: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                // const SizedBox(height: 64),
                // if (state.league?.startingMedals != null &&
                //     state.league!.startingMedals! > 0)
                //   const Padding(
                //     padding: EdgeInsets.all(16.0),
                //     child: Text('Tổng kết'),
                //   ),
                // if (state.league?.startingMedals != null &&
                //     state.league!.startingMedals! > 0)
                //   ...state.participants.map((e) {
                //     return EsportLeagueResultItem(e: e, state: state);
                //   }),
              ],
            ),
          );
        }
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
              child: index == 1
                  ? SvgPicture.asset(
                      'assets/svg/award-solid.svg',
                      width: 16,
                      height: 16,
                      colorFilter: const ColorFilter.mode(
                        Colors.red,
                        BlendMode.srcIn,
                      ),
                    )
                  : Text(
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
