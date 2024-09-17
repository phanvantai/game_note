import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
