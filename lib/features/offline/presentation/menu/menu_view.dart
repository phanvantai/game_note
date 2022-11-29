import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/helpers/app_helper.dart';
import 'package:game_note/main.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/database/database_manager.dart';
import '../../../../injection_container.dart';
import '../../../common/presentation/switch_mode_widget.dart';
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
                    try {
                      FilePickerResult? result =
                          await FilePicker.platform.pickFiles();

                      if (result != null) {
                        if (!result.files.single.path!
                            .endsWith(DatabaseManager.databaseFileName)) {
                          showAlertDialog(context, 'File is not valid');
                          return;
                        }
                        // close current db
                        await getIt<DatabaseManager>().close();

                        // get content picked file
                        File file = File(result.files.single.path!);
                        // copy to database file
                        await file.copy(dataFile);

                        // open current db
                        await getIt<DatabaseManager>().open();
                        showAlertDialog(
                            context, 'Database imported successfully');
                      } else {
                        // User canceled the picker
                        // do nothing
                      }
                    } catch (e) {
                      showAlertDialog(context, e.toString());
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
