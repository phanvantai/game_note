import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/presentation/notification/bloc/notification_bloc.dart';

import '../../../core/common/view_status.dart';
import '../../../core/databases/province.dart';
import '../../../core/ultils.dart';
import '../../../routing.dart';
import '../bloc/esport_bloc.dart';
import 'bloc/group_bloc.dart';
import 'widgets/group_item.dart';

class GroupsView extends StatelessWidget {
  const GroupsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<GroupBloc, GroupState>(
      builder: (context, state) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              centerTitle: false,
              title: Row(
                spacing: 4,
                children: [
                  BlocBuilder<EsportBloc, EsportState>(
                    builder: (context, state) => state.esportModel != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: state.esportModel!.image ?? '',
                              height: 32,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  Expanded(
                    child: TabBar(
                      padding: EdgeInsets.zero,
                      dividerColor: Colors.transparent,
                      tabAlignment: TabAlignment.start,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'Nhóm của tôi'),
                        Tab(text: 'Nhóm khác'),
                      ],
                    ),
                  ),
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
                      Navigator.pushNamed(context, Routing.notification);
                    },
                  ),
                ),
              ],
            ),
            body: Column(
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
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 80),
                              itemBuilder: (context, index) => GroupItem(
                                group: state.userGroups[index],
                                onTap: () async {
                                  await Navigator.of(context).pushNamed(
                                    Routing.groupDetail,
                                    arguments: state.userGroups[index],
                                  );
                                  if (context.mounted) {
                                    BlocProvider.of<GroupBloc>(context)
                                        .add(GetEsportGroups());
                                  }
                                },
                              ),
                              itemCount: state.userGroups.length,
                            ),
                      state.otherGroups.isEmpty
                          ? const AppEmptyState(
                              icon: Icons.group_outlined,
                              title: 'Không có nhóm nào',
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 80),
                              itemBuilder: (context, index) => GroupItem(
                                group: state.otherGroups[index],
                                onTap: () async {
                                  await Navigator.of(context).pushNamed(
                                    Routing.groupDetail,
                                    arguments: state.otherGroups[index],
                                  );
                                  if (context.mounted) {
                                    BlocProvider.of<GroupBloc>(context)
                                        .add(GetEsportGroups());
                                  }
                                },
                              ),
                              itemCount: state.otherGroups.length,
                            ),
                    ],
                  ),
                )
              ],
            ),
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
    final esportModel = context.read<EsportBloc>().state.esportModel;
    if (esportModel == null) {
      showToast('Chưa chọn một môn thể thao điện tử');
      return;
    }

    String groupName = '';
    String groupDescription = '';
    String selectedProvince = '';

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
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: null,
                  onChanged: (value) => selectedProvince = value!,
                  items: provinces
                      .map((e) => DropdownMenuItem(
                            value: e.name,
                            child: Text(e.name),
                          ))
                      .toList(),
                  decoration: appInputDecoration(
                    context: context,
                    hintText: 'Khu vực',
                    prefixIcon: Icons.location_on_outlined,
                  ),
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
                if (selectedProvince.isEmpty) {
                  showToast('Chọn tỉnh thành');
                  return;
                }
                BlocProvider.of<GroupBloc>(context).add(
                  CreateEsportGroup(
                    groupName: groupName,
                    esportId: esportModel.id,
                    description: groupDescription,
                    location: selectedProvince,
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
