import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pes_arena/l10n/l10n.dart';

void showAlertDialog(BuildContext context, String content) {
  showDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      content: Text(content),
      actions: [
        CupertinoDialogAction(
          child: Text(context.l10n.commonOk),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
