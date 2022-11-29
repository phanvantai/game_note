import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:game_note/injection_container.dart';

import '../../features/common/presentation/bloc/app_bloc.dart';
import 'shared_preferences_helper.dart';

AppStatus get appStatus {
  var abc = getIt<SharedPreferencesHelper>().isCommunityMode;
  switch (abc) {
    case true:
      return AppStatus.community;
    case false:
      return AppStatus.offline;
    default:
      return AppStatus.none;
  }
}

setAppStatus(AppStatus status) {
  getIt<SharedPreferencesHelper>().setCommunityMode(status.isCommunity);
}

showAlertDialog(BuildContext context, String content) {
  showDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      content: Text(content),
      actions: [
        CupertinoDialogAction(
          child: const Text('OK'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}
