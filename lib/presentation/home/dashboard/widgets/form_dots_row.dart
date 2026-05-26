import 'package:flutter/material.dart';
import 'package:pes_arena/l10n/l10n.dart';

import '../models/recent_match_summary.dart';

class FormDotsRow extends StatelessWidget {
  final List<RecentMatchSummary> matches;

  const FormDotsRow({super.key, required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Text(
        context.l10n.dashboardNoMatches,
        style: Theme.of(context).textTheme.bodyMedium,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: matches.reversed
          .map(
            (match) => Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: match.result.color.withValues(alpha: 0.75),
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

  String get label {
    switch (this) {
      case MatchResult.win:
        return 'T';
      case MatchResult.draw:
        return 'H';
      case MatchResult.loss:
        return 'B';
    }
  }

  String localizedLabel(BuildContext context) {
    switch (this) {
      case MatchResult.win:
        return context.l10n.dashboardWdlWinShort;
      case MatchResult.draw:
        return context.l10n.dashboardWdlDrawShort;
      case MatchResult.loss:
        return context.l10n.dashboardWdlLossShort;
    }
  }
}
