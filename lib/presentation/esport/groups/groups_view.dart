import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    final emptyImage = Image.asset(
      'assets/images/empty.png',
      height: 44,
    );
    return BlocBuilder<GroupBloc, GroupState>(
      builder: (context, state) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.indigo[100],
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
                        const Icon(Icons.notifications),
                        if (state.unreadNotificationsCount > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
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
                      if (state.userGroups.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 60, vertical: 8),
                          child: Center(
                            child: Column(
                              children: [
                                const SizedBox(height: 100),
                                emptyImage,
                                const Text(
                                  'Không có nhóm nào.',
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          itemBuilder: (context, index) => GroupItem(
                            group: state.userGroups[index],
                            onTap: () async {
                              final _ = await Navigator.of(context).pushNamed(
                                Routing.groupDetail,
                                arguments: state.userGroups[index],
                              );
                              // ignore: use_build_context_synchronously
                              BlocProvider.of<GroupBloc>(context)
                                  .add(GetEsportGroups());
                            },
                          ),
                          itemCount: state.userGroups.length,
                        ),
                      state.otherGroups.isEmpty
                          ? Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 100),
                                  emptyImage,
                                  const Text(
                                    'Không có nhóm nào',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemBuilder: (context, index) => GroupItem(
                                group: state.otherGroups[index],
                                onTap: () async {
                                  final _ =
                                      await Navigator.of(context).pushNamed(
                                    Routing.groupDetail,
                                    arguments: state.otherGroups[index],
                                  );
                                  // ignore: use_build_context_synchronously
                                  BlocProvider.of<GroupBloc>(context)
                                      .add(GetEsportGroups());
                                },
                              ),
                              itemCount: state.otherGroups.length,
                            )
                    ],
                  ),
                )
              ],
            ),
            floatingActionButton: ElevatedButton.icon(
              onPressed: () {
                final esportModel =
                    context.read<EsportBloc>().state.esportModel;
                if (esportModel == null) {
                  showToast('Chưa chọn một môn thể thao điện tử');
                  return;
                }
                // show create group dialog
                showDialog(
                  context: context,
                  builder: (BuildContext ctx) {
                    String groupName = '';
                    String groupDescription = '';
                    String selectedProvince = '';

                    return AlertDialog(
                      title: const Text('Tạo nhóm mới'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            onChanged: (value) {
                              groupName = value;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Tên nhóm',
                              // errorText: groupName.isEmpty
                              //     ? 'Tên nhóm không được để trống'
                              //     : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            onChanged: (value) {
                              groupDescription = value;
                            },
                            decoration: const InputDecoration(
                              labelText: 'Mô tả nhóm',
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: null,
                            onChanged: (value) {
                              selectedProvince = value!;
                            },
                            items: provinces
                                .map((e) => DropdownMenuItem(
                                      value: e.name,
                                      child: Text(e.name),
                                    ))
                                .toList(),
                            decoration: const InputDecoration(
                              labelText: 'Khu vực',
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Huỷ'),
                        ),
                        ElevatedButton(
                          style: ButtonStyle(
                              elevation: WidgetStateProperty.all(0)),
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
              },
              label: const Text('Tạo nhóm'),
              icon: const Icon(Icons.add),
              style: ButtonStyle(
                elevation: WidgetStateProperty.all(0),
                backgroundColor: WidgetStateProperty.all(Colors.red[100]),
              ),
            ),
          ),
        );
      },
    );
  }
}
