import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:game_note/presentation/users/bloc/user_bloc.dart';

import '../../../users/user_item.dart';

class GroupDetailView extends StatelessWidget {
  const GroupDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<GroupDetailBloc, GroupDetailState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: true,
          centerTitle: true,
          title: ListTile(
            leading: Image.asset('assets/images/pes_club_logo.png'),
            title: Text(
              state.group.groupName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            // trailing: state.isOwner
            //     ? IconButton(
            //         icon: const Icon(Icons.edit),
            //         onPressed: () {},
            //       )
            //     : null,
          ),
        ),
        body: ListView(
          children: [
            if (state.viewStatus == ViewStatus.loading)
              const LinearProgressIndicator(),
            ExpansionTile(
              leading: const Icon(
                Icons.description,
                color: Colors.black,
              ),
              expandedAlignment: Alignment.centerLeft,
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              showTrailingIcon: false,
              initiallyExpanded: true,
              maintainState: true,
              title: const Text(
                'Mô tả',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              shape: Border.all(color: Colors.transparent),
              collapsedShape: Border.all(color: Colors.transparent),
              children: [
                Text(
                  state.group.description,
                  textAlign: TextAlign.justify,
                )
              ],
            ),
            ExpansionTile(
              leading: const Icon(
                Icons.location_on,
                color: Colors.black,
              ),
              showTrailingIcon: false,
              initiallyExpanded: true,
              expandedAlignment: Alignment.centerLeft,
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
              title: const Text(
                'Khu vực hoạt động',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              shape: Border.all(color: Colors.transparent),
              collapsedShape: Border.all(color: Colors.transparent),
              children: [
                Text(state.group.location),
              ],
            ),
            ExpansionTile(
              leading: const Icon(
                Icons.people,
                color: Colors.black,
              ),
              showTrailingIcon: false,
              initiallyExpanded: true,
              title: const Text(
                'Thành viên',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              shape: Border.all(color: Colors.transparent),
              collapsedShape: Border.all(color: Colors.transparent),
              children: state.members
                  .map(
                    (user) => UserItem(user: user),
                  )
                  .toList(),
            ),
          ],
        ),
        floatingActionButton: state.isOwner
            ? TextButton.icon(
                onPressed: () {
                  // show dialog to search user add add to group
                  showDialog(
                    context: context,
                    builder: (BuildContext dialogContext) {
                      final userBloc = getIt<UserBloc>();
                      return BlocBuilder<UserBloc, UserState>(
                        bloc: userBloc..add(const SearchUser('')),
                        builder: (userContext, userState) => AlertDialog(
                          title: const Text('Thêm thành viên'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'Tìm kiếm',
                                ),
                                onChanged: (value) {
                                  userBloc.add(SearchUser(value));
                                },
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 300,
                                width: double.maxFinite,
                                child: ListView.builder(
                                  itemCount: userState.users.length,
                                  itemBuilder: (ctx, index) {
                                    final user = userState.users[index];
                                    return UserItem(
                                      user: user,
                                      onTap: () {
                                        // add user to group
                                        BlocProvider.of<GroupDetailBloc>(
                                                context)
                                            .add(
                                          AddMember(state.group.id, user.id),
                                        );
                                        Navigator.of(context).pop();
                                      },
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('Hủy'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                label: const Text('Thêm thành viên'),
                icon: const Icon(Icons.add),
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(Colors.red[100]),
                ),
              )
            : null,
      ),
      listener: (context, state) {
        if (state.errorMessage.isNotEmpty) {
          showToast(state.errorMessage);
        }
      },
    );
  }
}
