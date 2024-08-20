import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/common/presentation/auth/auth_view.dart';
import 'package:game_note/features/community/presentation/main_view.dart';

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
        return const MainView();
      case AppStatus.unknown:
        return const AuthView();
    }
  }
}
