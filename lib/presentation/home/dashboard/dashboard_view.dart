import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/widgets/shimmer.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/routing.dart';

import 'bloc/dashboard_bloc.dart';
import 'widgets/form_dots_row.dart';
import 'widgets/recent_matches_list.dart';
import 'widgets/stat_card_grid.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    final bloc = context.read<DashboardBloc>();
    if (bloc.state.viewStatus == ViewStatus.initial) {
      bloc.add(LoadDashboard());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, state) {
        if (state.viewStatus == ViewStatus.loading && state.stats == null) {
          return const _DashboardSkeleton();
        }

        if (state.viewStatus == ViewStatus.failure && state.stats == null) {
          return _DashboardError(
            message: state.errorMessage.isEmpty
                ? context.l10n.dashboardLoadError
                : state.errorMessage,
          );
        }

        final stats = state.stats;
        if (stats == null) return const SizedBox.shrink();

        return RefreshIndicator(
          onRefresh: () => _refresh(context.read<DashboardBloc>()),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
            children: [
              const _DashboardHero(),
              const SizedBox(height: 14),
              StatCardGrid(stats: stats),
              const SizedBox(height: 20),
              _SectionBlock(
                title: context.l10n.dashboardRecentForm10,
                icon: Icons.timeline_outlined,
                child: FormDotsRow(matches: stats.recentMatches),
              ),
              const SizedBox(height: 14),
              _SectionBlock(
                title: context.l10n.dashboardRecentMatches,
                icon: Icons.sports_soccer_outlined,
                child: RecentMatchesList(matches: stats.recentMatches),
              ),
              if (stats.recentMatches.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(context.l10n.dashboardNoMatches),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Keeps the spinner up until the reload settles (or gives up).
  Future<void> _refresh(DashboardBloc bloc) async {
    bloc.add(RefreshDashboard());
    await bloc.stream
        .firstWhere(
          (s) => s.viewStatus != ViewStatus.loading,
          orElse: () => bloc.state,
        )
        .timeout(const Duration(seconds: 20), onTimeout: () => bloc.state);
  }
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.query_stats_outlined,
              size: 24,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.dashboardHeroEyebrow,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    context.l10n.dashboardHeroTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: () => context.push(Routing.dashboardDetail),
              icon: const Icon(Icons.bar_chart_outlined, size: 18),
              label: Text(context.l10n.dashboardViewDetail),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionBlock({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.45,
            children: List.generate(4, (_) => const _SkeletonCard()),
          ),
          const SizedBox(height: 24),
          const ShimmerBox(height: 36),
          const SizedBox(height: 12),
          const ShimmerBox(height: 16, width: 200),
          const SizedBox(height: 24),
          for (var i = 0; i < 3; i++) ...[
            const ShimmerBox(height: 56),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            ShimmerBox(width: 28, height: 28),
            ShimmerBox(width: 96, height: 14),
            ShimmerBox(width: 54, height: 28),
          ],
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  final String message;

  const _DashboardError({required this.message});

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
              onPressed: () {
                context.read<DashboardBloc>().add(LoadDashboard());
              },
              icon: const Icon(Icons.refresh),
              label: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
