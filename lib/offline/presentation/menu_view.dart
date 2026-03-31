import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pes_arena/core/helpers/app_helper.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/main.dart';
import 'package:pes_arena/presentation/app/online_button.dart';
import 'package:share_plus/share_plus.dart';

import '../data/database/database_manager.dart';
import '../../injection_container.dart';

class MenuView extends StatelessWidget {
  const MenuView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        actions: const [OnlineButton()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'DỮ LIỆU',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.download_outlined,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    title: Text('Nhập dữ liệu', style: textTheme.bodyLarge),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    onTap: () => _importData(context),
                  ),
                  Divider(
                    height: 0.5,
                    indent: 56,
                    color: colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.upload_outlined,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    title: Text('Xuất dữ liệu', style: textTheme.bodyLarge),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    onTap: () => SharePlus.instance
                        .share(ShareParams(files: [XFile(dataFile)])),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _importData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null && context.mounted) {
        if (!result.files.single.path!
            .endsWith(DatabaseManager.databaseFileName)) {
          showAlertDialog(context,
              'Tệp tin không đúng.\nVui lòng sử dụng 1 tệp tin database game_note_database.db');
          return;
        }
        await getIt<DatabaseManager>().close();
        File file = File(result.files.single.path!);
        await file.copy(dataFile);
        await getIt<DatabaseManager>().open().then(
            // ignore: use_build_context_synchronously
            (_) => showAlertDialog(context, 'Dữ liệu đã được nhập thành công'));
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      showAlertDialog(context, e.toString());
    }
  }
}
