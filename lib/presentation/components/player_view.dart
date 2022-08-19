import 'package:flutter/material.dart';
import 'package:game_note/core/constants/constants.dart';

import '../../domain/entities/player_model.dart';

class PlayerView extends StatefulWidget {
  final bool? bold;
  final PlayerModel player;
  final Function(bool)? onClick;
  const PlayerView(this.player, {Key? key, required this.onClick, this.bold})
      : super(key: key);

  @override
  State<PlayerView> createState() => _PlayerViewState();
}

class _PlayerViewState extends State<PlayerView> {
  bool isSelected = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClick == null
          ? null
          : () {
              setState(() {
                isSelected = !isSelected;
              });
              if (widget.onClick != null) {
                widget.onClick!(isSelected);
              }
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.grey.withOpacity(0.3),
          // border: Border.all(
          //   color: isSelected ? Colors.orange : Colors.grey,
          // ),
          //borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            widget.player.fullname,
            style: widget.bold == true
                ? boldTextStyle
                : widget.onClick != null
                    ? boldTextStyle
                    : null,
          ),
        ),
      ),
    );
  }
}
