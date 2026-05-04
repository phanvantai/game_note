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
            appBar: _GroupsAppBar(
              onCreatePressed: () => _showCreateGroupDialog(context),
            ),
            body: _GroupsBody(state: state),
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
  final VoidCallback onCreatePressed;

  const _GroupsAppBar({required this.onCreatePressed});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: false,
      title: const _GroupsTabBar(),
      actions: [
        IconButton(
          tooltip: 'Tạo nhóm',
          onPressed: onCreatePressed,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _GroupsBody extends StatelessWidget {
  final GroupState state;

  const _GroupsBody({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
