import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/firebase/firestore/esport/league/match/gn_esport_match.dart';
import 'package:game_note/presentation/esport/tournament/tournament_detail/matches/widgets/create_custom_match_dialog.dart';
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
              length: 2,
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TabBar(
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(40),
                        color: Theme.of(context).secondaryHeaderColor,
                      ),
                      indicatorPadding:
                          const EdgeInsets.symmetric(horizontal: -16),
                      indicatorWeight: 0,
                      dividerColor: Colors.transparent,
                      tabAlignment: TabAlignment.start,
                      isScrollable: true,
                      tabs: const [
                        Tab(child: Text('Lịch thi đấu')),
                        Tab(child: Text('Kết quả')),
                      ],
                    ),
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
                              return Slidable(
                                endActionPane: ActionPane(
                                  motion: const StretchMotion(),
                                  children: [
                                    if (state.currentUserIsMember)
                                      SlidableAction(
                                        borderRadius: BorderRadius.circular(8),
                                        backgroundColor: Colors.red,
                                        icon: Icons.delete,
                                        onPressed: (context) {
                                          context
                                              .read<TournamentDetailBloc>()
                                              .add(DeleteEsportMatch(match));
                                        },
                                      ),
                                    if (state.currentUserIsMember)
                                      SlidableAction(
                                        borderRadius: BorderRadius.circular(8),
                                        backgroundColor: Colors.green,
                                        icon: Icons.monetization_on,
                                        onPressed: (ctx) {
                                          showDialog(
                                              context: context,
                                              builder: (ctx) {
                                                // create dialog to input medal of match
                                                final medalController =
                                                    TextEditingController()
                                                      ..text = match.medals
                                                          .toString();
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Nhập số lượng medal'),
                                                  content: TextField(
                                                    controller: medalController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: const Text('Hủy'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        FocusScope.of(context)
                                                            .unfocus();
                                                        // convert to int
                                                        final medal =
                                                            int.tryParse(
                                                                medalController
                                                                    .text);
                                                        // update match
                                                        if (medal == null) {
                                                          showToast(
                                                              'Nhập số lượng medal',
                                                              gravity:
                                                                  ToastGravity
                                                                      .TOP);
                                                          return;
                                                        }

                                                        context
                                                            .read<
                                                                TournamentDetailBloc>()
                                                            .add(
                                                              UpdateMatchMedals(
                                                                  match.id,
                                                                  medal),
                                                            );
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: const Text(
                                                          'Cập nhật'),
                                                    ),
                                                  ],
                                                );
                                              });
                                        },
                                      ),
                                  ],
                                ),
                                child: EsportMatchItem(
                                  match: match,
                                  onTap: state.currentUserIsMember
                                      ? () {
                                          // show dialog to update match
                                          _updateMatchDialog(context, match);
                                        }
                                      : null,
                                ),
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
                              return Slidable(
                                endActionPane: ActionPane(
                                  motion: const StretchMotion(),
                                  children: [
                                    if (state.currentUserIsMember)
                                      SlidableAction(
                                        borderRadius: BorderRadius.circular(8),
                                        backgroundColor: Colors.red,
                                        icon: Icons.delete,
                                        onPressed: (context) {
                                          context
                                              .read<TournamentDetailBloc>()
                                              .add(DeleteEsportMatch(match));
                                        },
                                      ),
                                    if (state.currentUserIsMember)
                                      SlidableAction(
                                        borderRadius: BorderRadius.circular(8),
                                        backgroundColor: Colors.green,
                                        icon: Icons.monetization_on,
                                        onPressed: (ctx) {
                                          showDialog(
                                              context: context,
                                              builder: (ctx) {
                                                // create dialog to input medal of match
                                                final medalController =
                                                    TextEditingController()
                                                      ..text = match.medals
                                                          .toString();
                                                return AlertDialog(
                                                  title: const Text(
                                                      'Nhập số lượng medal'),
                                                  content: TextField(
                                                    controller: medalController,
                                                    keyboardType:
                                                        TextInputType.number,
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: const Text('Hủy'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () {
                                                        FocusScope.of(context)
                                                            .unfocus();
                                                        // convert to int
                                                        final medal =
                                                            int.tryParse(
                                                                medalController
                                                                    .text);
                                                        // update match
                                                        if (medal == null) {
                                                          showToast(
                                                              'Nhập số lượng medal',
                                                              gravity:
                                                                  ToastGravity
                                                                      .TOP);
                                                          return;
                                                        }

                                                        context
                                                            .read<
                                                                TournamentDetailBloc>()
                                                            .add(
                                                              UpdateMatchMedals(
                                                                  match.id,
                                                                  medal),
                                                            );
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: const Text(
                                                          'Cập nhật'),
                                                    ),
                                                  ],
                                                );
                                              });
                                        },
                                      ),
                                  ],
                                ),
                                child: EsportMatchItem(
                                  match: match,
                                  onLongPress: state.currentUserIsMember
                                      ? () {
                                          // show dialog to update match
                                          _updateMatchDialog(context, match);
                                        }
                                      : null,
                                ),
                              );
                            },
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 8),
                            itemCount: state.results.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )),

          // if current user in group of league
          if (state.currentUserIsMember && state.participants.length > 1)
            // add participant button
            Positioned(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GNFloatingButton(
                    label: 'Thêm trận đấu',
                    onPressed: () {
                      // show dialog to pick 2 teams
                      showDialog(
                        context: context,
                        builder: (cxt) => CreateCustomMatchDialog(
                            users: state.users,
                            onMatchCreated: (home, away) {
                              context
                                  .read<TournamentDetailBloc>()
                                  .add(CreateCustomMatch(
                                    homeTeam: home,
                                    awayTeam: away,
                                  ));
                              Navigator.of(context).pop();
                            }),
                      );
                    },
                  ),
                  GNFloatingButton(
                    label: 'Thêm vòng đấu',
                    onPressed: () {
                      context
                          .read<TournamentDetailBloc>()
                          .add(const GenerateRound());
                    },
                  )
                ],
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
                FocusScope.of(context).unfocus();
                // update match
                if (homeScoreController.text.isEmpty ||
                    awayScoreController.text.isEmpty) {
                  showToast('Nhập kết quả trận đấu', gravity: ToastGravity.TOP);
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
