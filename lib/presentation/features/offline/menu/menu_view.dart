import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/main.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/switch_mode_widget.dart';
import 'bloc/menu_bloc.dart';
import 'components/menu_item_view.dart';
import 'members/members_view.dart';

class MenuView extends StatelessWidget {
  const MenuView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBloc, MenuState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        if (state.status.isMember) {
          return const MembersView();
        }
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Menu'),
            centerTitle: true,
            // actions: [],
            backgroundColor: Colors.black,
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SwitchModeWidget(),
                MenuItemView(
                  icon: const Icon(Icons.people),
                  title: 'Members',
                  callback: () => context.read<MenuBloc>().add(MembersEvent()),
                ),
                MenuItemView(
                  icon: const Icon(Icons.download),
                  title: 'Import data',
                  callback: () async {
                    FilePickerResult? result =
                        await FilePicker.platform.pickFiles();

                    if (result != null) {
                      // close current db
                      // await getIt<DatabaseManager>().close();

                      // get content picked file
                      // print(result.files.single.path);
                      File file = File(result.files.single.path!);
                      // print(await file.length());

                      // write data to file in db

                      // open current db

                    } else {
                      // User canceled the picker
                      // do nothing
                    }
                  },
                ),
                MenuItemView(
                  icon: const Icon(Icons.share),
                  title: 'Export data',
                  callback: () => Share.shareFiles([dataFile]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
