import 'package:flutter/material.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/l10n/l10n.dart';

class AddLeagueDialog extends StatefulWidget {
  final Function(String)? callback;
  const AddLeagueDialog({super.key, this.callback});

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
      title: Text(context.l10n.offlineCreateLeagueTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: appInputDecoration(
                context: context,
                hintText: context.l10n.offlineLeagueNameHint,
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
          child: Text(context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () async {
            Navigator.of(context).pop();
            if (widget.callback != null) {
              widget.callback!(controller.text);
            }
          },
          child: Text(context.l10n.commonCreate),
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
