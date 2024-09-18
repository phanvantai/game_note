import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:game_note/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item.dart';
import 'package:game_note/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_team.dart';

import '../../../../../widgets/gn_floating_button.dart';
import '../bloc/tournament_detail_bloc.dart';

class EsportMatchesView extends StatelessWidget {
  const EsportMatchesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TournamentDetailBloc, TournamentDetailState>(
        builder: (context, state) {
      return Stack(
        children: [
          // list matches
          DefaultTabController(
              length: 7,
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  TabBar(
                    tabAlignment: TabAlignment.start,
                    // labelStyle: const TextStyle(color: Colors.white),
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: const [
                      Tab(child: Text('Lịch thi đấu')),
                      Tab(child: Text('Kết quả')),
                      SizedBox.shrink(),
                      SizedBox.shrink(),
                      SizedBox.shrink(),
                      SizedBox.shrink(),
                      SizedBox.shrink(),
                    ],
                    //indicatorColor: Colors.orange,
                    //indicatorWeight: 4,
                    indicatorPadding:
                        const EdgeInsets.symmetric(horizontal: -16),
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: Theme.of(context).secondaryHeaderColor,
                    ),
                    indicatorWeight: 0,
                    dividerHeight: 0,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ListView.separated(
                            itemBuilder: (context, index) {
                              final match = state.fixtures[index];
                              return EsportMatchItem(
                                match: match,
                                onTap: state.currentUserIsMember
                                    ? () {
                                        // show dialog to update match
                                        _updateMatchDialog(context, match);
                                      }
                                    : null,
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemCount: state.fixtures.length,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: ListView.separated(
                            itemBuilder: (context, index) {
                              final match = state.results[index];
                              return EsportMatchItem(
                                match: match,
                                onLongPress: state.currentUserIsMember
                                    ? () {
                                        // show dialog to update match
                                        _updateMatchDialog(context, match);
                                      }
                                    : null,
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemCount: state.results.length,
                          ),
                        ),
                        const SizedBox.shrink(),
                        const SizedBox.shrink(),
                        const SizedBox.shrink(),
                        const SizedBox.shrink(),
                        const SizedBox.shrink(),
                      ],
                    ),
                  ),
                ],
              )),

          // if current user in group of league
          if (state.currentUserIsMember)
            // add participant button
            Positioned(
              right: 16.0,
              bottom: 16.0,
              child: GNFloatingButton(
                label: 'Thêm vòng đấu',
                onPressed: () {
                  context
                      .read<TournamentDetailBloc>()
                      .add(const GenerateRound());
                },
              ),
            ),
        ],
      );
    });
  }

  _updateMatchDialog(BuildContext context, GNEsportMatch match) {
    showDialog(
      context: context,
      builder: (ctx) {
        final homeScoreController = TextEditingController();
        final awayScoreController = TextEditingController();
        return AlertDialog(
          // title: const Text('Cập nhật kết quả'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (match.homeTeam != null)
                Row(
                  children: [
                    Expanded(
                      child: EsportMatchTeam(user: match.homeTeam!),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 32,
                      child: TextField(
                        controller: homeScoreController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              if (match.awayTeam != null)
                Row(
                  children: [
                    Expanded(
                      child: EsportMatchTeam(user: match.awayTeam!),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 32,
                      child: TextField(
                        controller: awayScoreController,
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
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
            ElevatedButton(
              onPressed: () {
                // update match
                if (homeScoreController.text.isEmpty ||
                    awayScoreController.text.isEmpty) {
                  showToast('Nhập kết quả trận đấu');
                  return;
                }
                // convert to int
                final homeScore = int.parse(homeScoreController.text);
                final awayScore = int.parse(awayScoreController.text);
                context.read<TournamentDetailBloc>().add(
                      UpdateEsportMatch(
                        match.copyWith(
                          homeScore: homeScore,
                          awayScore: awayScore,
                        ),
                      ),
                    );
                Navigator.of(context).pop();
              },
              child: const Text('Cập nhật'),
            ),
          ],
        );
      },
    );
  }
}
