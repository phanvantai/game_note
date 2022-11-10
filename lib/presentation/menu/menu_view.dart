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
            automaticallyImplyLeading: false,
            title: const Text('Menu'),
            centerTitle: true,
            // actions: [],
            backgroundColor: Colors.black,
          ),
          body: SafeArea(
            child: Column(
              children: [
                MenuItemView(
                  title: 'Community Mode',
                  icon: const Icon(Icons.accessibility),
                  trailing: Switch(
                    value: true,
                    onChanged: (value) {},
                  ),
                ),
                MenuItemView(
                  icon: const Icon(Icons.people),
                  title: 'Members',
                  callback: () => context.read<MenuBloc>().add(MembersEvent()),
                ),
                const MenuItemView(
                  icon: Icon(Icons.download),
                  title: 'Import data',
                ),
                MenuItemView(
                  icon: const Icon(Icons.share),
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
