import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/widgets/shimmer.dart';
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
                ? 'Lỗi tải dữ liệu'
                : state.errorMessage,
          );
        }

        final stats = state.stats;
        if (stats == null) return const SizedBox.shrink();

        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            StatCardGrid(stats: stats),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push(Routing.dashboardDetail),
                icon: const Icon(Icons.bar_chart_outlined),
                label: const Text('Xem chi tiết'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Phong độ 10 trận gần nhất',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FormDotsRow(matches: stats.recentMatches),
            const SizedBox(height: 24),
            Text(
              'Trận gần đây',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            RecentMatchesList(matches: stats.recentMatches),
            if (stats.recentMatches.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Chưa có trận nào'),
              ),
          ],
        );
      },
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
              label: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
}
