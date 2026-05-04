import 'package:flutter/material.dart';

import '../models/recent_match_summary.dart';

class FormDotsRow extends StatelessWidget {
  final List<RecentMatchSummary> matches;

  const FormDotsRow({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Text(
        'Chưa có trận nào',
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: matches
          .map(
            (match) => Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: match.result.color,
                shape: BoxShape.circle,
              ),
            ),
          )
          .toList(),
    );
  }
}

extension MatchResultColor on MatchResult {
  Color get color {
    switch (this) {
      case MatchResult.win:
        return Colors.green;
      case MatchResult.draw:
        return Colors.amber;
      case MatchResult.loss:
        return Colors.red;
    }
  }

  IconData get icon {
    switch (this) {
      case MatchResult.win:
        return Icons.check_circle;
      case MatchResult.draw:
        return Icons.remove_circle;
      case MatchResult.loss:
        return Icons.cancel;
    }
  }
}
