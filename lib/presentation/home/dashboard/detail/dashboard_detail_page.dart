import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pes_arena/core/cache/h2h_preferences.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/widgets/shimmer.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/routing.dart';

import '../../../../../widgets/gn_circle_avatar.dart';
import '../bloc/dashboard_bloc.dart';
import 'h2h_detail_page.dart';
import '../models/dashboard_stats.dart';
import '../models/opponent_stat.dart';
import '../models/recent_match_summary.dart';
import '../widgets/form_dots_row.dart';
import '../widgets/league_performance_chart.dart';

/// Full dashboard view — every metric the summary doc carries.
///
/// Reuses [DashboardBloc] via a fresh [BlocProvider] so this route works
/// independently of the home tab. Cache hit makes the first paint instant.
class DashboardDetailPage extends StatelessWidget {
  const DashboardDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DashboardBloc>()..add(LoadDashboard()),
      child: const _DashboardDetailScaffold(),
    );
  }
}

class _DashboardDetailScaffold extends StatelessWidget {
  const _DashboardDetailScaffold();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Bảng thống kê'),
        actions: [
          BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) {
              final loading = state.viewStatus == ViewStatus.loading;
              return IconButton(
                tooltip: 'Cập nhật từ máy chủ',
                onPressed: loading ? null : () => _confirmAndRefresh(context),
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<DashboardBloc, DashboardState>(
        builder: (context, state) {
          final stats = state.stats;
          if (stats == null) {
            if (state.viewStatus == ViewStatus.loading) {
              return const _DetailSkeleton();
            }
            return _ErrorState(
              message: state.errorMessage.isEmpty
                  ? 'Lỗi tải dữ liệu'
                  : state.errorMessage,
            );
          }
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.secondary.withValues(alpha: 0.12),
                  theme.scaffoldBackgroundColor,
                ],
              ),
            ),
            child: Stack(
              children: [
                ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    _DetailHero(stats: stats),
                    const SizedBox(height: 14),
                    _SectionHeader('Tổng quan'),
                    _OverviewBlock(stats: stats),
                    const SizedBox(height: 16),
                    _HeadToHeadSection(opponents: stats.opponents),
                    const SizedBox(height: 18),
                    _SectionShell(
                      title: 'Phong độ 5 giải gần nhất',
                      icon: Icons.show_chart_outlined,
                      child: LeaguePerformanceChart(
                        points: stats.leaguePerformance,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _SectionShell(
                      title: 'Phong độ 10 trận gần nhất',
                      icon: Icons.timeline_outlined,
                      child: FormDotsRow(matches: stats.recentMatches),
                    ),
                    const SizedBox(height: 24),
                    _SectionShell(
                      title: 'Trận gần đây',
                      icon: Icons.sports_soccer_outlined,
                      child: _DetailedMatchList(matches: stats.recentMatches),
                    ),
                    if (stats.recentMatches.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('Chưa có trận nào'),
                      ),
                  ],
                ),
                if (state.viewStatus == ViewStatus.loading)
                  const Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: _ShimmerBar(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailHero extends StatelessWidget {
  final DashboardStats stats;

  const _DetailHero({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final winRate = stats.winRate == null
        ? 'Chưa có'
        : '${(stats.winRate! * 100).round()}%';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.12),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.dashboard_customize_outlined,
                  color: colorScheme.onSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard detail',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Toàn cảnh thành tích thi đấu',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeroPill(
                  label: 'Win rate',
                  value: winRate,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  label: 'Hiệu số',
                  value: _signed(stats.goalDifference),
                  color: colorScheme.secondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroPill(
                  label: 'Đã đấu',
                  value: '${stats.matchesPlayed} trận',
                  color: const Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeroPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin shimmer-animated bar that sits at the top of the scroll area
/// while a refresh is in flight. Replaces the static
/// LinearProgressIndicator that wasn't visibly animating.
class _ShimmerBar extends StatelessWidget {
  const _ShimmerBar();

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      period: Duration(milliseconds: 1100),
      child: ShimmerBox(height: 3, borderRadius: BorderRadius.zero),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ShimmerBox(height: 18, width: 120),
          SizedBox(height: 12),
          ShimmerBox(height: 220),
          SizedBox(height: 24),
          ShimmerBox(height: 18, width: 100),
          SizedBox(height: 12),
          ShimmerBox(height: 140),
          SizedBox(height: 24),
          ShimmerBox(height: 18, width: 180),
          SizedBox(height: 12),
          ShimmerBox(height: 220),
        ],
      ),
    );
  }
}

/// Refresh hits the recompute Cloud Function which folds every match the
/// user has played — slow (~few seconds) and not free. Confirm before
/// firing so accidental taps don't cost server work.
Future<void> _confirmAndRefresh(BuildContext context) async {
  final bloc = context.read<DashboardBloc>();
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cập nhật thống kê?'),
      content: const Text(
        'Hệ thống sẽ tính lại toàn bộ thống kê từ dữ liệu trận đấu. '
        'Thao tác này có thể mất vài giây.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Huỷ'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Cập nhật'),
        ),
      ],
    ),
  );
  if (ok == true) {
    bloc.add(RefreshDashboard());
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionShell({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _OverviewBlock extends StatelessWidget {
  final DashboardStats stats;
  const _OverviewBlock({required this.stats});

  @override
  Widget build(BuildContext context) {
    final played = stats.matchesPlayed;
    final wdlCount = '${stats.wins} / ${stats.draws} / ${stats.losses}';
    final wdlPct =
        '${_pctOf(stats.wins, played)} / '
        '${_pctOf(stats.draws, played)} / '
        '${_pctOf(stats.losses, played)}';
    final goalsLine =
        '${stats.goals} / ${stats.goalsConceded} / '
        '${_signed(stats.goalDifference)}';

    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _MetricRow('Số giải tham gia', '${stats.tournamentsJoined}'),
            _MetricRow('Số trận', '$played'),
            _MetricRow(
              'Vô địch gần nhất',
              _lastChampionLabel(stats.lastChampionAt),
            ),
            _MetricRow('Thắng / Hoà / Thua', wdlCount),
            _MetricRow('Tỉ lệ T / H / T', wdlPct),
            _MetricRow('BT / BB / Hiệu số', goalsLine),
            _MetricRow(
              'Vô địch',
              _countAndRate(stats.championCount, stats.championRate),
            ),
            _MetricRow(
              'Á quân',
              _countAndRate(stats.runnerUpCount, stats.runnerUpRate),
            ),
          ],
        ),
      ),
    );
  }
}

/// Stateful wrapper for the H2H section. Owns the per-device
/// `minMatches` threshold so the user can tune how big the sample needs
/// to be before an opponent qualifies as Khắc tinh / Mồi ngon.
class _HeadToHeadSection extends StatefulWidget {
  final List<OpponentStat> opponents;

  const _HeadToHeadSection({required this.opponents});

  @override
  State<_HeadToHeadSection> createState() => _HeadToHeadSectionState();
}

class _HeadToHeadSectionState extends State<_HeadToHeadSection> {
  late int _minMatches;
  late H2HPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = getIt<H2HPreferences>();
    _minMatches = _prefs.minMatches;
  }

  Future<void> _openSettings() async {
    final newValue = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MinMatchesSheet(initialValue: _minMatches),
    );
    if (newValue == null || newValue == _minMatches) return;
    await _prefs.setMinMatches(newValue);
    if (!mounted) return;
    setState(() => _minMatches = newValue);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.48),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.groups_2_outlined,
                  color: colorScheme.secondary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Đối đầu', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      'Khắc tinh và mồi ngon theo lịch sử gặp nhau',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '(≥ $_minMatches trận)',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.tune, size: 20),
                tooltip: 'Tuỳ chỉnh ngưỡng',
                onPressed: _openSettings,
              ),
            ],
          ),
        ),
        _HeadToHeadBlock(opponents: widget.opponents, minMatches: _minMatches),
        if (widget.opponents.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      H2HDetailPage(opponents: widget.opponents),
                ),
              ),
              icon: const Icon(Icons.groups_2_outlined, size: 18),
              label: const Text('Xem tất cả đối thủ'),
            ),
          ),
        ],
      ],
    );
  }
}

class _MinMatchesSheet extends StatefulWidget {
  final int initialValue;
  const _MinMatchesSheet({required this.initialValue});

  @override
  State<_MinMatchesSheet> createState() => _MinMatchesSheetState();
}

class _MinMatchesSheetState extends State<_MinMatchesSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intValue = _value.round();
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ngưỡng số trận tối thiểu', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Đối thủ phải có ít nhất $intValue trận đối đầu mới được tính '
            'vào "Khắc tinh" / "Mồi ngon". Đặt cao hơn để loại bớt nhiễu khi '
            'mẫu nhỏ.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '$intValue',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text('trận', style: theme.textTheme.bodyMedium),
            ],
          ),
          Slider(
            value: _value.clamp(
              H2HPreferences.minBound.toDouble(),
              H2HPreferences.maxBound.toDouble(),
            ),
            min: H2HPreferences.minBound.toDouble(),
            max: H2HPreferences.maxBound.toDouble(),
            divisions: H2HPreferences.maxBound - H2HPreferences.minBound,
            label: '$intValue',
            onChanged: (v) => setState(() => _value = v),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Huỷ'),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(intValue),
                child: const Text('Lưu'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Two-line H2H leaderboard. See [_HeadToHeadSection] for the wrapper that
/// owns the configurable threshold.
class _HeadToHeadBlock extends StatelessWidget {
  final List<OpponentStat> opponents;
  final int minMatches;

  const _HeadToHeadBlock({required this.opponents, required this.minMatches});

  @override
  Widget build(BuildContext context) {
    final nemesis = pickTopByRate(
      opponents,
      (o) => o.losses,
      minMatches: minMatches,
    );
    final prey = pickTopByRate(
      opponents,
      (o) => o.wins,
      minMatches: minMatches,
    );

    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _H2HCard(
            label: 'Khắc tinh',
            metricName: 'thua',
            opponent: nemesis,
            count: (o) => o.losses,
            accent: colorScheme.error,
            icon: Icons.shield_outlined,
            minMatches: minMatches,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _H2HCard(
            label: 'Mồi ngon',
            metricName: 'thắng',
            opponent: prey,
            count: (o) => o.wins,
            accent: Colors.green,
            icon: Icons.bolt_outlined,
            minMatches: minMatches,
          ),
        ),
      ],
    );
  }
}

class _H2HCard extends StatelessWidget {
  final String label;
  final String metricName;
  final OpponentStat? opponent;
  final int Function(OpponentStat) count;
  final Color accent;
  final IconData icon;
  final int minMatches;

  const _H2HCard({
    required this.label,
    required this.metricName,
    required this.opponent,
    required this.count,
    required this.accent,
    required this.icon,
    required this.minMatches,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasOpponent = opponent != null;
    final n = hasOpponent ? count(opponent!) : 0;
    final pct = hasOpponent ? (opponent!.rate(n) * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.1), colorScheme.surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Type badge + percentage ──────────────────────────
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, color: accent, size: 12),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          label.toUpperCase(),
                          style: TextStyle(
                            color: accent,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                hasOpponent ? '$pct%' : '—',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: hasOpponent ? accent : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Player section ───────────────────────────────────
          if (hasOpponent) ...[
            Center(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: opponent!.opponentPhotoUrl != null
                        ? GNCircleAvatar(
                            size: 52,
                            photoUrl: opponent!.opponentPhotoUrl,
                          )
                        : _InitialsAvatar(
                            name: opponent!.opponentDisplayName,
                            size: 52,
                            accent: accent,
                          ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    opponent!.opponentDisplayName,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$n / ${opponent!.matchesPlayed} trận $metricName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── W / D / L breakdown ──────────────────────────
            Divider(height: 1, color: accent.withValues(alpha: 0.18)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _WDLCell(
                  label: 'Thắng',
                  value: opponent!.wins,
                  color: const Color(0xFF16A34A),
                ),
                _WDLCell(
                  label: 'Hoà',
                  value: opponent!.draws,
                  color: colorScheme.secondary,
                ),
                _WDLCell(
                  label: 'Thua',
                  value: opponent!.losses,
                  color: colorScheme.error,
                ),
              ],
            ),
          ] else ...[
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    Icon(
                      icon,
                      size: 32,
                      color: accent.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cần ≥ $minMatches trận\nđối đầu cùng người',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WDLCell extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _WDLCell({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '$value',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Pick the opponent with the highest `metric / matchesPlayed`. Only
/// opponents with at least `minMatches` total meetings count. Ties on
/// rate broken by total matches (more games = more confident signal).
@visibleForTesting
OpponentStat? pickTopByRate(
  List<OpponentStat> opponents,
  int Function(OpponentStat) metric, {
  required int minMatches,
}) {
  OpponentStat? best;
  double bestRate = 0;
  for (final o in opponents) {
    if (o.matchesPlayed < minMatches) continue;
    final rate = metric(o) / o.matchesPlayed;
    if (rate <= 0) continue;
    if (best == null ||
        rate > bestRate ||
        (rate == bestRate && o.matchesPlayed > best.matchesPlayed)) {
      best = o;
      bestRate = rate;
    }
  }
  return best;
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailedMatchList extends StatelessWidget {
  final List<RecentMatchSummary> matches;
  const _DetailedMatchList({required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Column(
      children: matches.map((m) {
        final resultColor = m.result.color;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: resultColor.withValues(alpha: 0.22)),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () =>
                  context.push(Routing.tournamentDetailPath(m.leagueId)),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: resultColor.withValues(alpha: 0.55),
                          width: 2,
                        ),
                      ),
                      child: m.opponentPhotoUrl != null
                          ? GNCircleAvatar(
                              photoUrl: m.opponentPhotoUrl,
                              size: 40,
                            )
                          : _InitialsAvatar(
                              name: m.opponentDisplayName,
                              size: 40,
                              accent: resultColor,
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.leagueName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.secondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            m.opponentDisplayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            DateFormat('dd/MM/yyyy').format(m.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: resultColor.withValues(alpha: 0.13),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: resultColor.withValues(alpha: 0.38),
                            ),
                          ),
                          child: Text(
                            m.result.label,
                            style: TextStyle(
                              color: resultColor,
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${m.userScore} - ${m.opponentScore}',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color accent;

  const _InitialsAvatar({
    required this.name,
    required this.size,
    required this.accent,
  });

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: TextStyle(
          color: accent,
          fontSize: size * 0.33,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () =>
                  context.read<DashboardBloc>().add(LoadDashboard()),
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}

String _pct(double? rate) {
  if (rate == null) return '—';
  return '${(rate * 100).round()}%';
}

String _pctOf(int part, int total) {
  if (total == 0) return '—';
  return '${(part / total * 100).round()}%';
}

String _countAndRate(int count, double? rate) {
  return '$count - ${_pct(rate)}';
}

String _signed(int n) {
  if (n > 0) return '+$n';
  return '$n';
}

String _lastChampionLabel(DateTime? date) {
  if (date == null) return '—';
  return DateFormat('dd/MM/yyyy').format(date);
}
