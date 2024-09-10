import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../auth/auth_view.dart';
import '../main/main_page.dart';
import 'bloc/app_bloc.dart';

class AppView extends StatelessWidget {
  const AppView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppBloc, AppState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        child: _appView(context, state),
      ),
    );
  }

  _appView(BuildContext context, AppState state) {
    switch (state.status) {
      case AppStatus.authenticated:
        return const MainPage();
      case AppStatus.unknown:
        return const AuthView();
    }
  }
}
