import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/features/community/bloc/community_bloc.dart';
import 'package:game_note/presentation/features/community/auth/auth_view.dart';
import 'package:game_note/presentation/features/community/online_view.dart';

class MainView extends StatelessWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CommunityBloc(),
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
