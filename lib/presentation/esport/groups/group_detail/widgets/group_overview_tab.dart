import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/models/group_overview.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/widgets/group_detail_hero.dart';
import 'package:pes_arena/widgets/gn_circle_avatar.dart';
import 'package:flutter/services.dart';

class GroupOverviewTab extends StatelessWidget {
  const GroupOverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    // Hero + description depend on group/members state, not on
    // overviewStatus, so we don't gate them behind buildWhen — let the
    // outer BlocBuilder rebuild whenever any of them changes.
    return BlocBuilder<GroupDetailBloc, GroupDetailState>(
      builder: (context, state) {
        final loading = state.overviewStatus == ViewStatus.loading;
        final filteredLoading =
            state.filteredOverviewStatus == ViewStatus.loading;
        final overview = state.activeOverview;
        final description = state.group.description;
        final isMember = state.currentUserIsMember;

        if (!isMember) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              GroupDetailHero(state: state),
              if (description.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionShell(
                  title: 'Mô tả',
                  icon: Icons.notes_outlined,
                  child: Text(
                    description,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.45),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ],
          );
        }

        return Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                _OverviewHeader(
                  loading: loading,
                  onRefresh: loading
                      ? null
                      : () => _confirmAndRefresh(context),
                ),
                const SizedBox(height: 12),
                GroupDetailHero(state: state),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionShell(
                    title: 'Mô tả',
                    icon: Icons.notes_outlined,
                    child: Text(
                      description,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.45),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
                if (state.leagues.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _YearFilterRow(state: state),
                ],
                const SizedBox(height: 16),
                if (state.overviewStatus == ViewStatus.failure &&
                    overview == null)
                  _ErrorBlock(message: state.overviewErrorMessage)
                else if (overview == null && (loading || filteredLoading))
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (overview == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text('Chưa có dữ liệu tổng quan'),
                    ),
                  )
                else if (overview.totalLeagues == 0)
                  const _EmptyBlock()
                else ...[
                  _AwardsSection(overview: overview),
                  const SizedBox(height: 16),
                  _PlayerStatsSection(overview: overview),
                ],
              ],
            ),
            if ((loading || filteredLoading) && overview != null)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 3),
              ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAndRefresh(BuildContext context) async {
    final bloc = context.read<GroupDetailBloc>();
    final groupId = bloc.state.group.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cập nhật thống kê?'),
        content: const Text(
          'Hệ thống sẽ tải lại toàn bộ giải đấu và tính lại thống kê group. '
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
      bloc.add(LoadGroupOverview(groupId, forceRefresh: true));
    }
  }
}

class _OverviewHeader extends StatelessWidget {
  final bool loading;
  final VoidCallback? onRefresh;

  const _OverviewHeader({required this.loading, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.dashboard_outlined,
            size: 20, color: theme.colorScheme.secondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Tổng quan group',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          tooltip: 'Cập nhật thống kê',
          onPressed: onRefresh,
          icon: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.secondary,
                  ),
                )
              : const Icon(Icons.refresh),
        ),
      ],
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.sports_score_outlined,
            size: 56,
            color: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Group chưa có giải đấu nào',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  final String message;

  const _ErrorBlock({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              color: Theme.of(context).colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message.isEmpty
                  ? 'Không thể tải dữ liệu tổng quan.'
                  : 'Lỗi tải dữ liệu: $message',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _AwardsSection extends StatelessWidget {
  final GroupOverview overview;

  const _AwardsSection({required this.overview});

  @override
  Widget build(BuildContext context) {
    final cards = <Widget>[];
    final c = Theme.of(context).colorScheme;
    if (overview.champion != null) {
      cards.add(_AwardCard(
        award: overview.champion!,
        title: 'Vô đối',
        subtitle: _rateLine(overview.champion!, suffix: 'giải vô địch'),
        icon: Icons.emoji_events,
        accent: const Color(0xFFFFC107),
      ));
    }
    if (overview.runnerUpKing != null) {
      cards.add(_AwardCard(
        award: overview.runnerUpKing!,
        title: 'Kẻ về nhì vĩ đại',
        subtitle: _rateLine(overview.runnerUpKing!, suffix: 'lần về nhì'),
        icon: Icons.workspace_premium_outlined,
        accent: const Color(0xFFB0BEC5),
      ));
    }
    // Hoà vương is computed server-side and stored on the overview, but
    // intentionally hidden from the UI per product call — kept on the
    // model so we can revive the card later without a server change.
    if (overview.master != null) {
      cards.add(_AwardCard(
        award: overview.master!,
        title: 'Cao thủ',
        subtitle:
            '${(overview.master!.value * 100).toStringAsFixed(0)}% thắng (${overview.master!.numerator}/${overview.master!.sampleSize})',
        icon: Icons.bolt_outlined,
        accent: Colors.lightGreen[600]!,
      ));
    }
    if (overview.ironDefense != null) {
      cards.add(_AwardCard(
        award: overview.ironDefense!,
        title: 'Hàng thủ thép',
        subtitle:
            '${overview.ironDefense!.value.toStringAsFixed(2)} bàn thua/trận (${overview.ironDefense!.sampleSize} trận)',
        icon: Icons.shield_outlined,
        accent: Colors.blueGrey[400]!,
      ));
    }

    if (cards.isEmpty) {
      return _SectionShell(
        title: 'Danh hiệu',
        icon: Icons.emoji_events_outlined,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Chưa đủ dữ liệu để trao danh hiệu (cần ít nhất 5 giải finished hoặc 5 trận đấu).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: c.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ),
      );
    }

    return _SectionShell(
      title: 'Danh hiệu',
      icon: Icons.emoji_events_outlined,
      child: Column(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i < cards.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  String _rateLine(GroupAward award, {required String suffix}) {
    final pct = (award.value * 100).toStringAsFixed(0);
    return '$pct% — ${award.numerator}/${award.sampleSize} $suffix';
  }
}

class _AwardCard extends StatelessWidget {
  final GroupAward award;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;

  const _AwardCard({
    required this.award,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.32)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 10),
          GNCircleAvatar(photoUrl: award.player.photoUrl, size: 40),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _displayName(award.player),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displayName(GNUser u) =>
      u.displayName ?? u.email ?? u.phoneNumber ?? u.id;
}

class _PlayerStatsSection extends StatelessWidget {
  final GroupOverview overview;

  const _PlayerStatsSection({required this.overview});

  @override
  Widget build(BuildContext context) {
    if (overview.playerStats.isEmpty) {
      return _SectionShell(
        title: 'Thống kê thành viên',
        icon: Icons.groups_outlined,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'Chưa có dữ liệu thành viên.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return _SectionShell(
      title: 'Thống kê thành viên',
      icon: Icons.groups_outlined,
      child: Column(
        children: [
          for (var i = 0; i < overview.playerStats.length; i++) ...[
            _PlayerStatRow(stats: overview.playerStats[i]),
            if (i < overview.playerStats.length - 1)
              const Divider(height: 16, thickness: 0.5),
          ],
        ],
      ),
    );
  }
}

class _PlayerStatRow extends StatelessWidget {
  final GroupPlayerStats stats;

  const _PlayerStatRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.colorScheme;
    return Row(
      children: [
        GNCircleAvatar(photoUrl: stats.player.photoUrl, size: 36),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stats.player.displayName ??
                    stats.player.email ??
                    stats.player.phoneNumber ??
                    stats.player.id,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                '${stats.matches} trận · '
                'Hiệu số ${stats.goalDifference >= 0 ? '+' : ''}${stats.goalDifference}',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: c.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        _WdlChip(
          label: 'T',
          count: stats.wins,
          rate: stats.winRate,
          color: Colors.green,
        ),
        const SizedBox(width: 6),
        _WdlChip(
          label: 'H',
          count: stats.draws,
          rate: stats.drawRate,
          color: Colors.amber[700]!,
        ),
        const SizedBox(width: 6),
        _WdlChip(
          label: 'B',
          count: stats.losses,
          rate: stats.lossRate,
          color: Colors.red,
        ),
      ],
    );
  }
}

class _WdlChip extends StatelessWidget {
  final String label;
  final int count;
  final double rate;
  final Color color;

  const _WdlChip({
    required this.label,
    required this.count,
    required this.rate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
          ),
          Text(
            '$label ${(rate * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}


class _YearFilterRow extends StatelessWidget {
  final GroupDetailState state;

  const _YearFilterRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final years = state.leagues
        .map((l) => l.startDate.year)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    if (years.isEmpty) return const SizedBox.shrink();

    final selected = state.selectedOverviewYear;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _YearChip(
            label: 'Tất cả',
            selected: selected == null,
            colorScheme: colorScheme,
            onTap: () {
              HapticFeedback.selectionClick();
              context
                  .read<GroupDetailBloc>()
                  .add(const FilterGroupOverviewByYear(null));
            },
          ),
          ...years.map(
            (year) => _YearChip(
              label: '$year',
              selected: selected == year,
              colorScheme: colorScheme,
              onTap: () {
                HapticFeedback.selectionClick();
                context
                    .read<GroupDetailBloc>()
                    .add(FilterGroupOverviewByYear(year));
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _YearChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _YearChip({
    required this.label,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.secondary
                : colorScheme.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? colorScheme.secondary
                  : colorScheme.secondary.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? colorScheme.onSecondary
                  : colorScheme.secondary,
            ),
          ),
        ),
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
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
