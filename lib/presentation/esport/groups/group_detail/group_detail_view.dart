import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/presentation/common/smart_back.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:pes_arena/routing.dart';

import '../../../users/user_item.dart';
import 'widgets/group_overview_tab.dart';

class GroupDetailView extends StatefulWidget {
  const GroupDetailView({super.key});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _overviewLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _overviewLoaded) return;
      _overviewLoaded = true;
      final bloc = context.read<GroupDetailBloc>();
      final state = bloc.state;
      final isMember = state.group.members.contains(state.currentUserId);
      if (!isMember) return;
      bloc
        ..add(LoadGroupOverview(state.group.id))
        ..add(LoadGroupLeagues(state.group.id));
    });
  }

  // coverage:ignore-start
  void _onTabChanged() {
    if (_tabController.index != 0 || _overviewLoaded) return;
    _overviewLoaded = true;
    final bloc = context.read<GroupDetailBloc>();
    final state = bloc.state;
    if (!state.group.members.contains(state.currentUserId)) return;
    bloc
      ..add(LoadGroupOverview(state.group.id))
      ..add(LoadGroupLeagues(state.group.id));
  }
  // coverage:ignore-end

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<GroupDetailBloc, GroupDetailState>(
      builder: (context, state) => Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: const SmartBackButton(),
          title: Text(
            state.group.groupName.isEmpty
                ? 'Chi tiết nhóm'
                : state.group.groupName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          actions: [
            if (state.isOwner)
              PopupMenuButton<_GroupAction>(
                enabled: state.deleteGroupStatus != ViewStatus.loading,
                onSelected: (action) {
                  if (action == _GroupAction.deleteGroup) {
                    _deleteGroup(context, state);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _GroupAction.deleteGroup,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          color: colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Xoá nhóm',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (state.currentUserIsMember && !state.isOwner)
              PopupMenuButton<_GroupAction>(
                onSelected: (action) {
                  if (action == _GroupAction.leaveGroup &&
                      state.currentUserId != null) {
                    _removeMember(true, context, state, state.currentUserId!);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _GroupAction.leaveGroup,
                    child: Row(
                      children: [
                        Icon(
                          Icons.exit_to_app,
                          color: colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Rời nhóm',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: AppPageBackground(
          child: SafeArea(
            child: Column(
              children: [
                _GroupDetailTabBar(controller: _tabController),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      const GroupOverviewTab(),
                      _MembersTab(
                        state: state,
                        // coverage:ignore-start
                        onAddMember: () => _addMember(context, state),
                        onRemoveMember: (userId) =>
                            _removeMember(false, context, state, userId),
                        // coverage:ignore-end
                        onToggleDeactivation: (userId, deactivate) =>
                            _toggleDeactivation(
                              context,
                              state,
                              userId,
                              deactivate,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      listener: (context, state) {
        // coverage:ignore-start
        if (state.errorMessage.isNotEmpty) {
          showToast(state.errorMessage);
        }
        if (state.deleteGroupErrorMessage.isNotEmpty) {
          showToast(state.deleteGroupErrorMessage);
        }
        // coverage:ignore-end
        if (state.deleteGroupStatus == ViewStatus.success) {
          try {
            context.read<GroupBloc>().add(GetEsportGroups());
          } catch (_) {
            // The detail route can be opened directly without the main shell's
            // GroupBloc in scope. Navigating to /groups recreates it.
          }
          context.go(Routing.groups);
        }
      },
    );
  }

  void _addMember(BuildContext context, GroupDetailState state) {
    context.push(
      '/group/${state.group.id}/add-member',
      extra: {
        'bloc': context.read<GroupDetailBloc>(),
        'members': Set<String>.from(state.group.members),
      },
    );
  }

  void _toggleDeactivation(
    BuildContext context,
    GroupDetailState state,
    String userId,
    bool deactivate,
  ) {
    BlocProvider.of<GroupDetailBloc>(context).add(
      ToggleMemberDeactivation(
        groupId: state.group.id,
        userId: userId,
        deactivate: deactivate,
      ),
    );
  }

  void _removeMember(
    bool currentUser,
    BuildContext context,
    GroupDetailState state,
    String userId,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: currentUser ? 'Rời nhóm' : 'Xóa thành viên',
      message: currentUser
          ? 'Bạn có chắc chắn muốn rời nhóm?'
          : 'Bạn có chắc chắn muốn xóa thành viên này không?',
      confirmText: currentUser ? 'Rời nhóm' : 'Xóa',
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      BlocProvider.of<GroupDetailBloc>(
        context,
      ).add(RemoveMember(state.group.id, userId));
    }
  }

  Future<void> _deleteGroup(
    BuildContext context,
    GroupDetailState state,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        String input = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canDelete = input.trim() == state.group.groupName;
            return AlertDialog(
              title: Text(context.l10n.groupDeleteTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.groupDeleteWarning,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    autofocus: true,
                    decoration: appInputDecoration(
                      context: context,
                      hintText: state.group.groupName,
                      prefixIcon: Icons.group_remove_outlined,
                    ),
                    onChanged: (value) => setDialogState(() => input = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(context.l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: canDelete
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  child: Text(context.l10n.groupDeleteTitle),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirmed == true && context.mounted) {
      context.read<GroupDetailBloc>().add(RequestDeleteGroup(state.group.id));
    }
  }
}

class _GroupDetailTabBar extends StatelessWidget {
  final TabController controller;

  const _GroupDetailTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Row(
          children: [
            Expanded(
              child: _GroupDetailTabItem(
                label: context.l10n.groupOverviewTab,
                selected: controller.index == 0,
                colorScheme: colorScheme,
                onTap: () => controller.animateTo(0),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _GroupDetailTabItem(
                label: context.l10n.groupMembersTab,
                selected: controller.index == 1,
                colorScheme: colorScheme,
                onTap: () => controller.animateTo(1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupDetailTabItem extends StatelessWidget {
  final String label;
  final bool selected;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _GroupDetailTabItem({
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

class _MembersTab extends StatelessWidget {
  final GroupDetailState state;
  final VoidCallback onAddMember;
  final void Function(String userId) onRemoveMember;
  final void Function(String userId, bool deactivate) onToggleDeactivation;

  const _MembersTab({
    required this.state,
    required this.onAddMember,
    required this.onRemoveMember,
    required this.onToggleDeactivation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final deactivatedMembers = state.group.deactivatedMembers;
    return CustomScrollView(
      slivers: [
        if (state.isOwner)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: FilledButton.icon(
                onPressed: onAddMember,
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: Text(context.l10n.groupAddMemberTitle),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, state.isOwner ? 8 : 12, 16, 96),
          sliver: SliverList.separated(
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemCount: state.members.length,
            itemBuilder: (_, index) {
              final user = state.members[index];
              final isDeactivated = deactivatedMembers.contains(user.id);
              return _MemberTile(
                child: UserItem(
                  user: user,
                  subtitle: isDeactivated
                      ? Chip(
                          label: Text(context.l10n.groupInactive),
                          labelStyle: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                  trailing: state.isOwner
                      ? !user.isCurrentUser
                            ? PopupMenuButton<_MemberAction>(
                                icon: const Icon(Icons.more_vert, size: 20),
                                // coverage:ignore-start
                                onSelected: (action) {
                                  if (action == _MemberAction.remove) {
                                    onRemoveMember(user.id);
                                  } else if (action ==
                                      _MemberAction.deactivate) {
                                    onToggleDeactivation(user.id, true);
                                  } else if (action ==
                                      _MemberAction.reactivate) {
                                    onToggleDeactivation(user.id, false);
                                  }
                                },
                                // coverage:ignore-end
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: isDeactivated
                                        ? _MemberAction.reactivate
                                        : _MemberAction.deactivate,
                                    child: Row(
                                      children: [
                                        Icon(
                                          isDeactivated
                                              ? Icons.person_outlined
                                              : Icons.person_off_outlined,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          isDeactivated
                                              ? 'Kích hoạt lại'
                                              : 'Ngừng hoạt động',
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: _MemberAction.remove,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.person_remove_outlined,
                                          color: colorScheme.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Xoá khỏi nhóm',
                                          style: TextStyle(
                                            color: colorScheme.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            // coverage:ignore-start
                            : Icon(
                                Icons.admin_panel_settings_outlined,
                                color: colorScheme.secondary,
                                size: 20,
                              )
                      // coverage:ignore-end
                      : user.id == state.group.ownerId
                      ? Icon(
                          Icons.admin_panel_settings_outlined,
                          color: colorScheme.secondary,
                          size: 20,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MemberTile extends StatelessWidget {
  final Widget child;

  const _MemberTile({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }
}

enum _GroupAction { leaveGroup, deleteGroup }

enum _MemberAction { deactivate, reactivate, remove }
