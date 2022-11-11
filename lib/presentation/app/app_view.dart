import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/app/bloc/app_bloc.dart';
import 'package:game_note/presentation/features/community/online_view.dart';
import 'package:game_note/presentation/app/general_view.dart';
import 'package:game_note/presentation/features/offline/offline_view.dart';

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
      case AppStatus.community:
        return const OnlineView();
      case AppStatus.offline:
        return const OfflineView();
      default:
        return const GeneralView();
    }
  }
}
