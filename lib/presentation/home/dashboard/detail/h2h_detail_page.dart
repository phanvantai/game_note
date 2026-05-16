import 'package:flutter/material.dart';

import '../../../../widgets/gn_circle_avatar.dart';
import '../../../common/smart_back.dart';
import '../models/opponent_stat.dart';

enum _SortMode { mostMatches, bestWinRate, worstWinRate }

class H2HDetailPage extends StatefulWidget {
  final List<OpponentStat> opponents;

  const H2HDetailPage({super.key, required this.opponents});

  @override
  State<H2HDetailPage> createState() => _H2HDetailPageState();
}

class _H2HDetailPageState extends State<H2HDetailPage> {
  _SortMode _sort = _SortMode.mostMatches;

  List<OpponentStat> get _sorted {
    final list = [...widget.opponents];
    switch (_sort) {
      case _SortMode.mostMatches:
        list.sort((a, b) => b.matchesPlayed.compareTo(a.matchesPlayed));
      case _SortMode.bestWinRate:
        list.sort((a, b) => b.rate(b.wins).compareTo(a.rate(a.wins)));
      case _SortMode.worstWinRate:
        list.sort((a, b) => b.rate(b.losses).compareTo(a.rate(a.losses)));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sorted = _sorted;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const SmartBackButton(),
        title: const Text('Lịch sử đối đầu'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _SortBar(current: _sort, onChanged: (s) => setState(() => _sort = s)),
          ),
        ),
      ),
      body: sorted.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.groups_2_outlined,
                    size: 48,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có dữ liệu đối đầu',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemCount: sorted.length,
              separatorBuilder: (context, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _OpponentCard(
                opponent: sorted[i],
                rank: i + 1,
              ),
            ),
    );
  }
}

// ── Sort bar ─────────────────────────────────────────────────────────────────

class _SortBar extends StatelessWidget {
  final _SortMode current;
  final ValueChanged<_SortMode> onChanged;

  const _SortBar({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          _SortOption(label: 'Nhiều trận', mode: _SortMode.mostMatches, current: current, onChanged: onChanged),
          _SortOption(label: 'Thắng nhiều', mode: _SortMode.bestWinRate, current: current, onChanged: onChanged),
          _SortOption(label: 'Thua nhiều', mode: _SortMode.worstWinRate, current: current, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  final String label;
  final _SortMode mode;
  final _SortMode current;
  final ValueChanged<_SortMode> onChanged;

  const _SortOption({
    required this.label,
    required this.mode,
    required this.current,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selected = current == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: selected ? colorScheme.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? colorScheme.onSecondary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Opponent card ─────────────────────────────────────────────────────────────

class _OpponentCard extends StatelessWidget {
  final OpponentStat opponent;
  final int rank;

  const _OpponentCard({required this.opponent, required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final o = opponent;
    final winRate = o.matchesPlayed == 0 ? 0.0 : o.wins / o.matchesPlayed;
    final drawRate = o.matchesPlayed == 0 ? 0.0 : o.draws / o.matchesPlayed;
    final lossRate = o.matchesPlayed == 0 ? 0.0 : o.losses / o.matchesPlayed;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          // ── Avatar ──────────────────────────────────────────
          Stack(
            children: [
              o.opponentPhotoUrl != null
                  ? GNCircleAvatar(size: 48, photoUrl: o.opponentPhotoUrl)
                  : _InitialsAvatar(name: o.opponentDisplayName, size: 48),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$rank',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurfaceVariant,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // ── Name + bar + stats ───────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        o.opponentDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${o.matchesPlayed} trận',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Stacked W/D/L bar
                _WDLBar(winRate: winRate, drawRate: drawRate, lossRate: lossRate),

                const SizedBox(height: 8),

                // W / D / L counts
                Row(
                  children: [
                    _StatChip(label: 'T', value: o.wins, color: const Color(0xFF16A34A)),
                    const SizedBox(width: 6),
                    _StatChip(label: 'H', value: o.draws, color: const Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    _StatChip(label: 'B', value: o.losses, color: const Color(0xFFDC2626)),
                    const Spacer(),
                    Text(
                      '${(winRate * 100).round()}% thắng',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: winRate >= 0.5
                            ? const Color(0xFF16A34A)
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stacked W/D/L progress bar ────────────────────────────────────────────────

class _WDLBar extends StatelessWidget {
  final double winRate;
  final double drawRate;
  final double lossRate;

  const _WDLBar({
    required this.winRate,
    required this.drawRate,
    required this.lossRate,
  });

  @override
  Widget build(BuildContext context) {
    final total = winRate + drawRate + lossRate;
    if (total == 0) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(99),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: SizedBox(
        height: 6,
        child: Row(
          children: [
            if (winRate > 0)
              Expanded(
                flex: (winRate * 1000).round(),
                child: const ColoredBox(color: Color(0xFF16A34A)),
              ),
            if (drawRate > 0)
              Expanded(
                flex: (drawRate * 1000).round(),
                child: const ColoredBox(color: Color(0xFF9CA3AF)),
              ),
            if (lossRate > 0)
              Expanded(
                flex: (lossRate * 1000).round(),
                child: const ColoredBox(color: Color(0xFFDC2626)),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Stat chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatChip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ── Initials avatar (same fallback as H2HCard) ────────────────────────────────

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _InitialsAvatar({required this.name, required this.size});

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontSize: size * 0.33,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
