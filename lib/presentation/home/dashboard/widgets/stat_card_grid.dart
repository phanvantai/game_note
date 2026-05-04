import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      childAspectRatio: 1.45,
      children: [
        _StatCard(
          title: 'Giải đã tham gia',
          value: '${stats.tournamentsJoined}',
          icon: Icons.emoji_events_outlined,
        ),
        _StatCard(
          title: 'Tỉ lệ vô địch',
          value: _percent(stats.championCount, finishedCount),
          icon: Icons.workspace_premium_outlined,
        ),
        _StatCard(
          title: 'Tỉ lệ á quân',
          value: _percent(stats.runnerUpCount, finishedCount),
          icon: Icons.military_tech_outlined,
        ),
        _StatCard(
          title: 'Vô địch gần nhất',
          value: _lastChampionLabel(stats.lastChampionAt),
          icon: Icons.history_outlined,
        ),
      ],
    );
  }

  String _percent(int value, int total) {
    if (total == 0) return '—';
    return '${(value / total * 100).round()}%';
  }

  String _lastChampionLabel(DateTime? date) {
    if (date == null) return '—';
    final now = DateTime.now();
    final days = now.difference(date).inDays;
    if (days >= 0 && days < 30) {
      if (days == 0) return 'Hôm nay';
      return '$days ngày trước';
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
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: colorScheme.primary),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
