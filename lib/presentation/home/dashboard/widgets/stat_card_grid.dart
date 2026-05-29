import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pes_arena/l10n/l10n.dart';

import '../models/dashboard_stats.dart';

class StatCardGrid extends StatelessWidget {
  final DashboardStats stats;

  const StatCardGrid({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final finishedCount = stats.finishedTournaments;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.65,
      children: [
        _StatCard(
          title: context.l10n.dashboardTournamentsJoined,
          value: '${stats.tournamentsJoined}',
          icon: Icons.emoji_events_outlined,
        ),
        _StatCard(
          title: context.l10n.dashboardChampionRate,
          value: _percent(stats.championCount, finishedCount),
          icon: Icons.workspace_premium_outlined,
        ),
        _StatCard(
          title: context.l10n.dashboardRunnerUpRate,
          value: _percent(stats.runnerUpCount, finishedCount),
          icon: Icons.military_tech_outlined,
        ),
        _StatCard(
          title: context.l10n.dashboardLatestChampion,
          value: _lastChampionLabel(context, stats.lastChampionAt),
          icon: Icons.history_outlined,
        ),
      ],
    );
  }

  String _percent(int value, int total) {
    if (total == 0) return '—';
    return '${(value / total * 100).round()}%';
  }

  String _lastChampionLabel(BuildContext context, DateTime? date) {
    if (date == null) return '—';
    final now = DateTime.now();
    final days = now.difference(date).inDays;
    if (days >= 0 && days < 30) {
      if (days == 0) return context.l10n.dashboardToday;
      return context.l10n.dashboardDaysAgo(days);
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
