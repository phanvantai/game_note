import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/core/databases/province.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/presentation/esport/bloc/esport_bloc.dart';
import 'package:game_note/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:game_note/routing.dart';

class GroupsBody extends StatelessWidget {
  const GroupsBody({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emptyImage = Image.asset(
      'assets/images/empty.png',
      height: 44,
    );
    return BlocBuilder<GroupBloc, GroupState>(
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                ExpansionTile(
                  backgroundColor: Colors.orange[100],
                  collapsedBackgroundColor: Colors.orange[100],
                  shape: Border.all(color: Colors.transparent),
                  title: const Text('Nhóm của bạn'),
                  initiallyExpanded: true,
                  maintainState: true,
                  children: [
                    if (state.viewStatus.isLoading)
                      const LinearProgressIndicator()
                    else if (state.userGroups.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 60, vertical: 8),
                        child: Center(
                          child: Column(
                            children: [
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
                      ...state.userGroups.map(
                        (group) => Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white60,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            leading:
                                Image.asset('assets/images/pes_club_logo.png'),
                            title: Text(group.groupName),
                            subtitle: Text(
                              'Thành viên: ${group.members.length}  Khu vực: ${group.location}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            onTap: () => Navigator.of(context).pushNamed(
                              Routing.groupDetail,
                              arguments: group,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                ExpansionTile(
                  backgroundColor: Colors.lime[100],
                  collapsedBackgroundColor: Colors.lime[100],
                  shape: Border.all(color: Colors.transparent),
                  title: const Text('Nhóm khác'),
                  initiallyExpanded: true,
                  showTrailingIcon: false,
                ),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.lime[100],
                    ),
                    child: state.otherGroups.isEmpty
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
                        : ListView.separated(
                            itemBuilder: (context, index) => ListTile(
                              title: Text(state.otherGroups[index].groupName),
                            ),
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 4),
                            itemCount: state.otherGroups.length,
                          ),
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: ElevatedButton.icon(
            onPressed: () {
              final esportModel = context.read<EsportBloc>().state.esportModel;
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
                        style:
                            ButtonStyle(elevation: WidgetStateProperty.all(0)),
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
        );
      },
    );
  }
}
