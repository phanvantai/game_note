import 'package:flutter/material.dart';
import 'package:game_note/_old/viewmodels/random_view_model.dart';
import 'package:game_note/_old/views/components/league_view.dart';
import 'package:game_note/presentation/wheel_spinner_view.dart';
import 'package:provider/provider.dart';

class RandomView extends StatefulWidget {
  const RandomView({Key? key}) : super(key: key);

  @override
  State<RandomView> createState() => _RandomViewState();
}

class _RandomViewState extends State<RandomView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RandomWheelViewModel>(
        builder: ((context, viewmodel, child) {
      return viewmodel.picking
          ? _listLeague(viewmodel)
          : WheelSpinnerView(list: viewmodel.listSelected);
    }));
  }

  _listLeague(RandomWheelViewModel viewModel) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Text("Selected ${viewModel.listSelected.length}"),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: viewModel.listLeague.length,
            itemBuilder: (context, index) {
              return LeagueView(
                league: viewModel.listLeague[index],
                callback: () {
                  viewModel.updateSelection();
                },
              );
            },
          ),
        )
      ],
    );
  }
}
