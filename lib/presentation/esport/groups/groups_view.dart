import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/presentation/notification/bloc/notification_bloc.dart';

import '../../../core/common/view_status.dart';
import '../../../core/ultils.dart';
import '../../../firebase/firestore/esport/group/gn_esport_group.dart';
import '../../../routing.dart';
import 'bloc/group_bloc.dart';
import 'widgets/group_item.dart';

class GroupsView extends StatelessWidget {
  final bool embedded;

  const GroupsView({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<GroupBloc, GroupState>(
      builder: (context, state) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: embedded ? null : _GroupsAppBar(colorScheme: colorScheme),
            body: _GroupsBody(state: state, embedded: embedded),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () => _showCreateGroupDialog(context),
              label: const Text('Tạo nhóm'),
              icon: const Icon(Icons.add),
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

class _GroupsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ColorScheme colorScheme;

  const _GroupsAppBar({required this.colorScheme});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      title: Row(
        spacing: 4,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset('assets/images/pes.jpg', height: 32),
          ),
          const Expanded(child: _GroupsTabBar()),
        ],
      ),
      actions: [
        BlocBuilder<NotificationBloc, NotificationState>(
          builder: (context, state) => IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_outlined),
                if (state.unreadNotificationsCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      width: 8,
                      height: 8,
                    ),
                  ),
              ],
            ),
            onPressed: () {
              context.push(Routing.notification);
            },
          ),
        ),
      ],
    );
  }
}

class _GroupsBody extends StatelessWidget {
  final GroupState state;
  final bool embedded;

  const _GroupsBody({required this.state, required this.embedded});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (embedded) const _GroupsTabBar(),
        if (state.viewStatus == ViewStatus.loading)
          const LinearProgressIndicator(),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            children: [
              state.userGroups.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.group_outlined,
                      title: 'Không có nhóm nào',
                      subtitle: 'Tạo nhóm mới để bắt đầu',
                    )
                  : _GroupsList(groups: state.userGroups),
              state.otherGroups.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.group_outlined,
                      title: 'Không có nhóm nào',
                    )
                  : _GroupsList(groups: state.otherGroups),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupsTabBar extends StatelessWidget {
  const _GroupsTabBar();

  @override
  Widget build(BuildContext context) {
    return const TabBar(
      padding: EdgeInsets.zero,
      dividerColor: Colors.transparent,
      tabAlignment: TabAlignment.start,
      isScrollable: true,
      tabs: [
        Tab(text: 'Nhóm của tôi'),
        Tab(text: 'Nhóm khác'),
      ],
    );
  }
}

class _GroupsList extends StatelessWidget {
  final List<GNEsportGroup> groups;

  const _GroupsList({required this.groups});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
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
