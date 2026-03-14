import 'package:flutter/material.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';

class AddLeagueDialog extends StatefulWidget {
  final Function(String)? callback;
  const AddLeagueDialog({Key? key, this.callback}) : super(key: key);

  @override
  State<AddLeagueDialog> createState() => _AddLeagueDialogState();
}

class _AddLeagueDialogState extends State<AddLeagueDialog> {
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
      title: const Text('Tạo giải đấu'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: appInputDecoration(
                context: context,
                hintText: 'Tên giải đấu',
                prefixIcon: Icons.emoji_events_outlined,
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
          onPressed: () async {
            Navigator.of(context).pop();
            if (widget.callback != null) {
              widget.callback!(controller.text);
            }
          },
          child: const Text('Tạo'),
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
