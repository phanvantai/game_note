import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/app/switch_mode_widget.dart';
import 'package:game_note/presentation/features/community/bloc/community_bloc.dart';
import 'package:game_note/presentation/features/offline/menu/components/menu_item_view.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            const SwitchModeWidget(),
            MenuItemView(
              title: 'Logout',
              icon: const Icon(Icons.start),
              callback: () => context.read<CommunityBloc>().add(LogoutEvent()),
            ),
          ],
        ),
      ),
    );
  }
}
