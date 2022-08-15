import 'package:flutter/material.dart';
import 'package:game_note/_old/views/components/player_view.dart';
import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/injection_container.dart';

import '../../../domain/entities/player_model.dart';

class SelectPlayerView extends StatefulWidget {
  final int numberOfPlayer;
  final Function(List<PlayerModel>) onSelectDone;
  const SelectPlayerView(
    this.numberOfPlayer, {
    Key? key,
    required this.onSelectDone,
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
          ElevatedButton(
            onPressed: selectedPlayers.length == widget.numberOfPlayer
                ? () {
                    widget.onSelectDone(selectedPlayers);
                  }
                : null,
            child: const Text("Done"),
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                selectedPlayers.length == widget.numberOfPlayer
                    ? Colors.orange
                    : Colors.orange.withOpacity(0.5),
              ),
            ),
          ),
          Text("Selecting 2 player. Selected: ${selectedPlayers.length}"),
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

  void loadPlayer() async {
    var newPlayers = await getIt<DatabaseManager>().players();
    setState(() {
      players = newPlayers;
    });
  }
}
