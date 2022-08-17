import 'package:flutter/material.dart';
import 'package:game_note/core/ultils.dart';

class PlayerItemView extends StatelessWidget {
  final String text;
  final int score;
  final bool ingame;
  const PlayerItemView({
    Key? key,
    required this.text,
    required this.score,
    this.ingame = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ingame == false
        ? Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                ClipRRect(
                  child: Container(
                    decoration: BoxDecoration(
                      color: randomObject(Colors.primaries),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    width: 24,
                    height: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  score.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          )
        : Row(
            children: [
              ClipRRect(
                child: Container(
                  decoration: BoxDecoration(
                    color: randomObject(Colors.primaries),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  width: 16,
                  height: 16,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                ),
              ),
              const Spacer(),
              Text(
                score.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.w300,
                ),
              ),
              const SizedBox(width: 8),
            ],
          );
  }
}
