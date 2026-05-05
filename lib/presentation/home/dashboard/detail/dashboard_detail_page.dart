import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:pes_arena/core/cache/h2h_preferences.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/widgets/shimmer.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/routing.dart';

import '../bloc/dashboard_bloc.dart';
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
    return Scaffold(
      appBar: AppBar(
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
          return Stack(
            children: [
              ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _SectionHeader('Tổng quan'),
                  _OverviewBlock(stats: stats),
                  const SizedBox(height: 24),
                  _HeadToHeadSection(opponents: stats.opponents),
                  const SizedBox(height: 24),
                  _SectionHeader('Phong độ 5 giải gần nhất'),
                  LeaguePerformanceChart(points: stats.leaguePerformance),
                  const SizedBox(height: 24),
                  _SectionHeader('Phong độ 10 trận gần nhất'),
                  const SizedBox(height: 8),
                  FormDotsRow(matches: stats.recentMatches),
                  const SizedBox(height: 24),
                  _SectionHeader('Trận gần đây'),
                  const SizedBox(height: 8),
                  _DetailedMatchList(matches: stats.recentMatches),
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
          );
        },
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
      child: ShimmerBox(
        height: 3,
        borderRadius: BorderRadius.zero,
      ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
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

    return Card(
      margin: EdgeInsets.zero,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Text('Đối đầu', style: theme.textTheme.titleMedium),
              const SizedBox(width: 8),
              Text(
                '(≥ $_minMatches trận)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.tune, size: 20),
                tooltip: 'Tuỳ chỉnh ngưỡng',
                onPressed: _openSettings,
              ),
            ],
          ),
        ),
        _HeadToHeadBlock(
          opponents: widget.opponents,
          minMatches: _minMatches,
        ),
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
          Text(
            'Ngưỡng số trận tối thiểu',
            style: theme.textTheme.titleMedium,
          ),
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

  const _HeadToHeadBlock({
    required this.opponents,
    required this.minMatches,
  });

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

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            _H2HRow(
              label: 'Khắc tinh',
              metricName: 'thua',
              opponent: nemesis,
              count: (o) => o.losses,
              accent: Colors.red,
              minMatches: minMatches,
            ),
            const Divider(height: 1),
            _H2HRow(
              label: 'Mồi ngon',
              metricName: 'thắng',
              opponent: prey,
              count: (o) => o.wins,
              accent: Colors.green,
              minMatches: minMatches,
            ),
          ],
        ),
      ),
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

class _H2HRow extends StatelessWidget {
  final String label;
  final String metricName;
  final OpponentStat? opponent;
  final int Function(OpponentStat) count;
  final Color accent;
  final int minMatches;

  const _H2HRow({
    required this.label,
    required this.metricName,
    required this.opponent,
    required this.count,
    required this.accent,
    required this.minMatches,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasOpponent = opponent != null;
    final n = hasOpponent ? count(opponent!) : 0;
    final pct = hasOpponent ? (opponent!.rate(n) * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 10),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(label, style: theme.textTheme.bodyMedium),
                    const Spacer(),
                    if (hasOpponent)
                      Text(
                        '$pct%',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accent,
                        ),
                      )
                    else
                      Text('—', style: theme.textTheme.titleMedium),
                  ],
                ),
                const SizedBox(height: 4),
                if (hasOpponent)
                  Text(
                    '${opponent!.opponentDisplayName} · '
                    '$n/${opponent!.matchesPlayed} trận $metricName',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                else
                  Text(
                    'Cần ít nhất $minMatches trận đối đầu',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
    return Column(
      children: matches.map((m) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            onTap: () => context.push(Routing.tournamentDetailPath(m.leagueId)),
            leading: Icon(m.result.icon, color: m.result.color),
            title: Text(
              '${DateFormat('dd/MM/yyyy').format(m.date)} · ${m.leagueName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              'Bạn ${m.userScore} - ${m.opponentScore} ${m.opponentDisplayName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      }).toList(),
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
