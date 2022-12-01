import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/community/presentation/auth/bloc/auth_bloc.dart';
import 'package:game_note/features/community/presentation/online_view.dart';

import 'auth/auth_view.dart';
import 'bloc/community_bloc.dart';

class MainView extends StatelessWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => CommunityBloc()..add(InitialComEvent())),
        BlocProvider(create: (_) => AuthBloc()),
      ],
      child: BlocBuilder<CommunityBloc, CommunityState>(
        builder: (context, state) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child: _buildWidget(context, state),
          );
        },
      ),
    );
  }

  _buildWidget(BuildContext context, CommunityState state) {
    switch (state.status) {
      case CommunityStatus.loggedIn:
        return const OnlineView();
      default:
        return const AuthView();
    }
  }
}
