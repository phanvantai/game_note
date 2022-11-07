import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/main.dart';
import 'package:game_note/presentation/menu/bloc/menu_bloc.dart';
import 'package:game_note/presentation/menu/components/menu_item_view.dart';
import 'package:game_note/presentation/menu/members/members_view.dart';
import 'package:share_plus/share_plus.dart';

class MenuView extends StatelessWidget {
  const MenuView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuBloc, MenuState>(
      buildWhen: (previous, current) => previous.status != current.status,
      builder: (context, state) {
        if (state.status.isMember) {
          return const MembersView();
        }
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            actions: [
              Switch.adaptive(
                value: true,
                onChanged: (value) =>
                    context.read<MenuBloc>().add(SwitchThemeEvent()),
              )
            ],
            backgroundColor: Colors.black,
          ),
          body: SafeArea(
            child: Column(
              children: [
                MenuItemView(
                  title: 'Members',
                  callback: () => context.read<MenuBloc>().add(MembersEvent()),
                ),
                const MenuItemView(title: 'Import data'),
                MenuItemView(
                  title: 'Export data',
                  callback: () {
                    Share.shareFiles([dataFile]);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
