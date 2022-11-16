import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/common/presentation/switch_mode_widget.dart';

import '../../../offline/presentation/menu/components/menu_item_view.dart';
import '../bloc/community_bloc.dart';

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
