import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';

import '../../../core/common/view_status.dart';
import '../../../core/ultils.dart';
import '../../../firebase/firestore/esport/group/gn_esport_group.dart';
import '../../../routing.dart';
import 'bloc/group_bloc.dart';
import 'widgets/group_item.dart';

class GroupsView extends StatelessWidget {
  const GroupsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GroupBloc, GroupState>(
      builder: (context, state) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            body: _GroupsBody(
              state: state,
              onCreatePressed: () => _showCreateGroupDialog(context),
            ),
          ),
        );
      },
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    String groupName = '';
    String groupDescription = '';

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Tạo nhóm mới'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) => groupName = value,
                  decoration: appInputDecoration(
                    context: context,
                    hintText: 'Tên nhóm',
                    prefixIcon: Icons.group_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => groupDescription = value,
                  decoration: appInputDecoration(
                    context: context,
                    hintText: 'Mô tả nhóm',
                    prefixIcon: Icons.description_outlined,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Huỷ'),
            ),
            FilledButton(
              onPressed: () {
                if (groupName.isEmpty) {
                  showToast('Tên nhóm không được để trống');
                  return;
                }
                BlocProvider.of<GroupBloc>(context).add(
                  CreateEsportGroup(
                    groupName: groupName,
                    description: groupDescription,
                  ),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Tạo nhóm'),
            ),
          ],
        );
      },
    );
  }
}

class _GroupsBody extends StatelessWidget {
  final GroupState state;
  final VoidCallback onCreatePressed;

  const _GroupsBody({required this.state, required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.secondary.withValues(alpha: 0.16),
            theme.scaffoldBackgroundColor,
            colorScheme.primary.withValues(alpha: 0.06),
          ],
          stops: const [0, 0.46, 1],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (state.viewStatus == ViewStatus.loading)
              const LinearProgressIndicator(minHeight: 3),
            _GroupsHero(state: state, onCreatePressed: onCreatePressed),
            const _GroupsTabBar(),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  state.userGroups.isEmpty
                      ? const _GroupsEmptyState(
                          title: 'Không có nhóm nào',
                          subtitle: 'Tạo nhóm mới để bắt đầu',
                        )
                      : _GroupsList(groups: state.userGroups),
                  state.otherGroups.isEmpty
                      ? const _GroupsEmptyState(title: 'Không có nhóm nào')
                      : _GroupsList(groups: state.otherGroups),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupsHero extends StatelessWidget {
  final GroupState state;
  final VoidCallback onCreatePressed;

  const _GroupsHero({required this.state, required this.onCreatePressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final myGroups = state.userGroups.length;
    final discoverGroups = state.otherGroups.length;
    final members = {
      for (final group in [...state.userGroups, ...state.otherGroups])
        ...group.members,
    }.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.26),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.secondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.groups_2_outlined,
                  color: colorScheme.onSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Community hub',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Quản lý đội nhóm PES',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: 'Tạo nhóm',
                child: FilledButton.icon(
                  onPressed: onCreatePressed,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tạo mới'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _HeroStat(label: 'Của tôi', value: '$myGroups'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: 'Khám phá',
                  value: '$discoverGroups',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(label: 'Member', value: '$members'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;

  const _HeroStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
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

class _GroupsTabBar extends StatelessWidget {
  const _GroupsTabBar();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 46,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.42)),
      ),
      child: TabBar(
        padding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: colorScheme.onSecondary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        tabs: const [
          Tab(text: 'Nhóm của tôi'),
          Tab(text: 'Nhóm khác'),
        ],
      ),
    );
  }
}

class _GroupsList extends StatelessWidget {
  final List<GNEsportGroup> groups;

  const _GroupsList({required this.groups});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 96),
      itemBuilder: (context, index) => GroupItem(
        group: groups[index],
        onTap: () async {
          await context.push(
            Routing.groupDetailPath(groups[index].id),
            extra: groups[index],
          );
          if (context.mounted) {
            BlocProvider.of<GroupBloc>(context).add(GetEsportGroups());
          }
        },
      ),
      itemCount: groups.length,
    );
  }
}

class _GroupsEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _GroupsEmptyState({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colorScheme.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                Icons.group_outlined,
                color: colorScheme.secondary,
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
