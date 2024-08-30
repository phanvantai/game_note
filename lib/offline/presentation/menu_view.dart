import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:game_note/core/helpers/app_helper.dart';
import 'package:game_note/main.dart';
import 'package:game_note/presentation/app/online_button.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database/database_manager.dart';
import '../../injection_container.dart';

class MenuView extends StatelessWidget {
  const MenuView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      appBar: AppBar(
        centerTitle: true,
        actions: const [OnlineButton()],
        backgroundColor: Colors.white70,
      ),
      body: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Nhập dữ liệu',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () async {
                try {
                  FilePicker.platform.pickFiles().then((value) async {
                    if (value != null) {
                      if (!value.files.single.path!
                          .endsWith(DatabaseManager.databaseFileName)) {
                        // ignore: use_build_context_synchronously
                        showAlertDialog(context,
                            'Tệp tin không đúng.\nVui lòng sử dụng 1 tệp tin database game_note_database.db');
                        return;
                      }
                      // close current db
                      await getIt<DatabaseManager>().close();

                      // get content picked file
                      File file = File(value.files.single.path!);
                      // copy to database file
                      await file.copy(dataFile);

                      // open current db
                      await getIt<DatabaseManager>()
                          .open()
                          .then((value) => showAlertDialog(
                              // ignore: use_build_context_synchronously
                              context,
                              'Dữ liệu đã được nhập thành công'));
                    } else {
                      // User canceled the picker
                      // do nothing
                    }
                  });
                } catch (e) {
                  showAlertDialog(context, e.toString());
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Xuất dữ liệu',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () => Share.shareXFiles([XFile(dataFile)]),
            ),
          ],
        ),
      ),
    );
  }
}
