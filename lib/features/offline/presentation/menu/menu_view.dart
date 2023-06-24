import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:game_note/core/helpers/app_helper.dart';
import 'package:game_note/main.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/database/database_manager.dart';
import '../../../../injection_container.dart';
import '../../../common/presentation/switch_mode_widget.dart';
import 'components/menu_item_view.dart';

class MenuView extends StatelessWidget {
  const MenuView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              icon: const Icon(Icons.download),
              title: 'Nhập dữ liệu',
              callback: () async {
                try {
                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles();

                  if (result != null) {
                    if (!result.files.single.path!
                        .endsWith(DatabaseManager.databaseFileName)) {
                      showAlertDialog(context,
                          'Tệp tin không đúng.\nVui lòng sử dụng 1 tệp tin database game_note_database.db');
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
                    showAlertDialog(context, 'Dữ liệu đã được nhập thành công');
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
              title: 'Xuất dữ liệu',
              callback: () => Share.shareXFiles([XFile(dataFile)]),
            ),
          ],
        ),
      ),
    );
  }
}
