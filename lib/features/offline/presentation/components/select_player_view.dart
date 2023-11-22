// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:game_note/features/offline/presentation/components/player_view.dart';
import 'package:game_note/features/offline/data/database/database_manager.dart';
import 'package:game_note/injection_container.dart';

import '../../domain/entities/player_model.dart';

class SelectPlayerView extends StatefulWidget {
  final int? numberOfPlayer;
  final Function(List<PlayerModel>)? onSelectDone;
  final Function(List<PlayerModel>, bool)? enableSection;
  const SelectPlayerView({
    Key? key,
    this.numberOfPlayer,
    this.onSelectDone,
    this.enableSection,
  }) : super(key: key);

  @override
  State<SelectPlayerView> createState() => _SelectPlayerViewState();
}

class _SelectPlayerViewState extends State<SelectPlayerView> {
  List<PlayerModel> players = [];
  List<PlayerModel> selectedPlayers = [];
  @override
  void initState() {
    super.initState();
    loadPlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.onSelectDone != null)
            ElevatedButton(
              onPressed: enableDoneButton
                  ? () {
                      widget.onSelectDone!(selectedPlayers);
                    }
                  : null,
              child: const Text("Done"),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(
                  enableDoneButton ? Colors.orange : Colors.grey,
                ),
              ),
            ),
          if (widget.numberOfPlayer != null)
            Text("Selecting 2 player. Selected: ${selectedPlayers.length}")
          else
            Text("Selected: ${selectedPlayers.length}"),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    const SizedBox(height: 8),
                    PlayerView(
                      players[index],
                      onClick: (isSelected) {
                        setState(() {
                          isSelected
                              ? selectedPlayers.add(players[index])
                              : selectedPlayers.remove(players[index]);
                        });
                        if (widget.enableSection != null) {
                          widget.enableSection!(
                              selectedPlayers, enableDoneButton);
                        }
                      },
                    )
                  ],
                );
              },
            ),
          )
        ],
      ),
    );
  }

  bool get enableDoneButton {
    if (widget.numberOfPlayer == null) {
      return selectedPlayers.length > 2;
    } else {
      return selectedPlayers.length == widget.numberOfPlayer;
    }
  }

  void loadPlayer() async {
    var newPlayers = await getIt<DatabaseManager>().players();
    setState(() {
      players = newPlayers;
    });
  }
}
