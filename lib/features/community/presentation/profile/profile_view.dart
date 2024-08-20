import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
            MenuItemView(
              title: 'Sign Out',
              icon: const Icon(Icons.start),
              callback: () => context.read<CommunityBloc>().add(SignOutEvent()),
            ),
          ],
        ),
      ),
    );
  }
}
