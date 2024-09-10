import 'package:flutter/material.dart';

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
      content: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            TextField(
              autofocus: true,
              decoration:
                  const InputDecoration.collapsed(hintText: 'Tên giải đấu'),
              controller: controller,
              onChanged: (string) {
                setState(() {
                  fullname = string;
                });
              },
              //cursorColor: Colors.white,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                if (widget.callback != null) {
                  widget.callback!(controller.text);
                }
              },
              child: const Text("Tạo"),
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
