import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../routing.dart';
import '../main/main_page.dart';
import 'bloc/app_bloc.dart';

/// Home route widget. The router's redirect callback guarantees that anyone
/// reaching `/` has [AppStatus.authenticated], so this just renders the
/// authed shell — the login bounce lives in `routing.dart`.
class AppView extends StatelessWidget {
  const AppView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppBloc, AppState>(
      listenWhen: (previous, current) =>
          previous.enableFootballFeature != current.enableFootballFeature,
      listener: (context, state) {
        context.go(Routing.app);
      },
      child: const MainPage(),
    );
  }
}
