// ignore_for_file: sort_child_properties_last

import 'package:flutter/material.dart';
import 'package:pes_arena/offline/presentation/components/player_view.dart';
import 'package:pes_arena/offline/data/database/database_manager.dart';
import 'package:pes_arena/injection_container.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (widget.onSelectDone != null)
            FilledButton(
              onPressed: enableDoneButton
                  ? () {
                      widget.onSelectDone!(selectedPlayers);
                    }
                  : null,
              child: const Text("Done"),
            ),
          const SizedBox(height: 8),
          if (widget.numberOfPlayer != null)
            Text(
              "Selecting 2 player. Selected: ${selectedPlayers.length}",
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            )
          else
            Text(
              "Selected: ${selectedPlayers.length}",
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: players.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return PlayerView(
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
