import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/l10n/l10n.dart';

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
          title: Text(ctx.l10n.groupCreateTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  onChanged: (value) => groupName = value,
                  decoration: appInputDecoration(
                    context: context,
                    hintText: ctx.l10n.groupNameHint,
                    prefixIcon: Icons.group_outlined,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  onChanged: (value) => groupDescription = value,
                  decoration: appInputDecoration(
                    context: context,
                    hintText: ctx.l10n.groupDescriptionHint,
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
              child: Text(ctx.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                if (groupName.isEmpty) {
                  showToast(ctx.l10n.groupNameRequired);
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
              child: Text(ctx.l10n.groupCreateButton),
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
    return AppPageBackground(
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
                      ? _GroupsEmptyState(
                          title: context.l10n.groupEmptyTitle,
                          subtitle: context.l10n.groupEmptySubtitle,
                        )
                      : _GroupsList(groups: state.userGroups),
                  state.otherGroups.isEmpty
                      ? _GroupsEmptyState(title: context.l10n.groupEmptyTitle)
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.groups_2_outlined,
                size: 24,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.groupHeroEyebrow,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.groupHeroTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Tooltip(
                message: context.l10n.groupCreateButton,
                child: FilledButton.icon(
                  onPressed: onCreatePressed,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(context.l10n.groupCreateNew),
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
                child: _HeroStat(
                  label: context.l10n.groupMineStat,
                  value: '$myGroups',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: context.l10n.groupDiscoverStat,
                  value: '$discoverGroups',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HeroStat(
                  label: context.l10n.groupMembersStat,
                  value: '$members',
                ),
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
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
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
    final tabController = DefaultTabController.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: AnimatedBuilder(
        animation: tabController,
        builder: (context, _) {
          final selectedIndex = tabController.index;

          return Row(
            children: [
              Expanded(
                child: _GroupsTabOption(
                  label: context.l10n.groupMyGroupsTab,
                  selected: selectedIndex == 0,
                  colorScheme: colorScheme,
                  onTap: () => tabController.animateTo(0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _GroupsTabOption(
                  label: context.l10n.groupOtherGroupsTab,
                  selected: selectedIndex == 1,
                  colorScheme: colorScheme,
                  onTap: () => tabController.animateTo(1),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GroupsTabOption extends StatelessWidget {
  final String label;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _GroupsTabOption({
    required this.label,
    required this.selected,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.only(top: 8, bottom: 7),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 22 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.group_outlined,
              size: 40,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
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
