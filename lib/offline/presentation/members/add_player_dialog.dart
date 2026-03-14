import 'package:flutter/material.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/offline/domain/entities/player_model.dart';
import 'package:pes_arena/offline/data/database/database_manager.dart';
import 'package:pes_arena/injection_container.dart';

class AddPlayerDialog extends StatefulWidget {
  final VoidCallback? callback;
  const AddPlayerDialog({Key? key, this.callback}) : super(key: key);

  @override
  State<AddPlayerDialog> createState() => _AddPlayerDialogState();
}

class _AddPlayerDialogState extends State<AddPlayerDialog> {
  late TextEditingController controller;
  String fullname = "";

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Thêm người chơi'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: appInputDecoration(
                context: context,
                hintText: 'Tên người chơi',
                prefixIcon: Icons.person_outline,
              ),
              controller: controller,
              onChanged: (string) {
                setState(() {
                  fullname = string;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: fullname.length > 2
              ? () {
                  var player =
                      PlayerModel(fullname: controller.text, level: "Noob");
                  getIt<DatabaseManager>()
                      .insertPlayer(player)
                      .then((value) {
                    controller.text = "";
                    setState(() {
                      fullname = "";
                    });
                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                    if (widget.callback != null) {
                      widget.callback!();
                    }
                  });
                }
              : null,
          child: const Text('Thêm'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
