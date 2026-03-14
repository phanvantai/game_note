import 'package:flutter/material.dart';
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
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
          color: isSelected
              ? colorScheme.secondary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            widget.player.fullname,
            style: (widget.bold == true || widget.onClick != null)
                ? textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? colorScheme.onSecondary
                        : colorScheme.onSurface,
                  )
                : textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}
