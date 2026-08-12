import 'package:flutter/material.dart';

import '../main/main_page.dart';

/// Home route widget. The router's redirect callback guarantees that anyone
/// reaching `/` has [AppStatus.authenticated], so this just renders the
/// authed shell — the login bounce lives in `routing.dart`.
class AppView extends StatelessWidget {
  final int initialTabIndex;

  const AppView({super.key, this.initialTabIndex = 0});

  @override
  Widget build(BuildContext context) {
    return MainPage(initialTabIndex: initialTabIndex);
  }
}
