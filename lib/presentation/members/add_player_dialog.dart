import 'package:flutter/material.dart';
import 'package:game_note/domain/entities/player_model.dart';
import 'package:game_note/core/database/database_manager.dart';
import 'package:game_note/injection_container.dart';

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
      content: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            TextField(
              decoration:
                  const InputDecoration.collapsed(hintText: 'Player name'),
              controller: controller,
              onChanged: (string) {
                setState(() {
                  fullname = string;
                });
              },
              cursorColor: Colors.white,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: fullname.length > 2
                  ? () async {
                      var player =
                          PlayerModel(fullname: controller.text, level: "Noob");
                      await getIt<DatabaseManager>().insertPlayer(player);
                      controller.text = "";
                      setState(() {
                        fullname = "";
                      });
                      Navigator.of(context).pop();
                      if (widget.callback != null) {
                        widget.callback!();
                      }
                    }
                  : null,
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}