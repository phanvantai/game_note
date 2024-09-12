import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/ultils.dart';
import 'package:game_note/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';

import '../../../../widgets/gn_circle_avatar.dart';

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
                    (user) => ListTile(
                      title: Text(user.displayName ??
                          user.email ??
                          user.phoneNumber ??
                          user.id),
                      leading: GNCircleAvatar(
                        photoUrl: user.photoUrl,
                        size: 40,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        floatingActionButton: state.isOwner
            ? TextButton.icon(
                onPressed: () {},
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
