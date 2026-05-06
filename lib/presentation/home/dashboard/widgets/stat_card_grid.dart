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
      childAspectRatio: 1.35,
      children: [
        _StatCard(
          title: 'Giải đã tham gia',
          value: '${stats.tournamentsJoined}',
          icon: Icons.emoji_events_outlined,
          tone: _StatTone.gold,
        ),
        _StatCard(
          title: 'Tỉ lệ vô địch',
          value: _percent(stats.championCount, finishedCount),
          icon: Icons.workspace_premium_outlined,
          tone: _StatTone.violet,
        ),
        _StatCard(
          title: 'Tỉ lệ á quân',
          value: _percent(stats.runnerUpCount, finishedCount),
          icon: Icons.military_tech_outlined,
          tone: _StatTone.blue,
        ),
        _StatCard(
          title: 'Vô địch gần nhất',
          value: _lastChampionLabel(stats.lastChampionAt),
          icon: Icons.history_outlined,
          tone: _StatTone.rose,
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

enum _StatTone { gold, violet, blue, rose }

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final _StatTone tone;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = switch (tone) {
      _StatTone.gold => const Color(0xFFE0A11B),
      _StatTone.violet => const Color(0xFF7C3AED),
      _StatTone.blue => const Color(0xFF2563EB),
      _StatTone.rose => const Color(0xFFE11D48),
    };
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.55)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.13), colorScheme.surface],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
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
