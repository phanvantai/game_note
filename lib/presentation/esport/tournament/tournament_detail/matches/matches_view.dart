import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/esport/tournament/tournament_detail/matches/widgets/esport_match_item.dart';

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
                  const TabBar(
                    tabAlignment: TabAlignment.start,
                    // labelStyle: const TextStyle(color: Colors.white),
                    isScrollable: true,
                    indicatorSize: TabBarIndicatorSize.label,
                    tabs: [
                      Tab(child: Text('Lịch thi đấu')),
                      Tab(child: Text('Kết quả')),
                      SizedBox.shrink(),
                      SizedBox.shrink(),
                      SizedBox.shrink(),
                      SizedBox.shrink(),
                      SizedBox.shrink(),
                    ],
                    //indicatorColor: Colors.orange,
                    // indicatorWeight: 4,
                    // indicatorPadding:
                    //     const EdgeInsets.symmetric(horizontal: -16),
                    // indicator: BoxDecoration(
                    //   borderRadius: BorderRadius.circular(40),
                    //   color: Colors.black,
                    // ),
                    dividerHeight: 0,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        ListView.separated(
                          itemBuilder: (context, index) {
                            final match = state.fixtures[index];
                            return EsportMatchItem(match: match);
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 8),
                          itemCount: state.fixtures.length,
                        ),
                        ListView.separated(
                          itemBuilder: (context, index) {
                            final match = state.results[index];
                            return EsportMatchItem(match: match);
                          },
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 4),
                          itemCount: state.results.length,
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
}
