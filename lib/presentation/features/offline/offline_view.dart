import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/features/offline/solo_round/solo_round_view.dart';

import 'league/league_view.dart';
import 'menu/bloc/menu_bloc.dart';
import 'menu/menu_view.dart';

class OfflineView extends StatefulWidget {
  const OfflineView({Key? key}) : super(key: key);

  @override
  State<OfflineView> createState() => _OfflineViewState();
}

class _OfflineViewState extends State<OfflineView>
    with TickerProviderStateMixin {
  Map<BottomNavigationBarItem, Widget> tabs = const {
    BottomNavigationBarItem(
      icon: Icon(Icons.sports_soccer),
      label: 'Leagues',
    ): LeagueView(),
    BottomNavigationBarItem(
      icon: Icon(Icons.sports_baseball),
      label: 'Solo',
    ): SoloRoundView(),
    BottomNavigationBarItem(
      icon: Icon(Icons.menu),
      label: 'More',
    ): MenuView(),
  };
  late TabController _tabController;
  @override
  void initState() {
    _tabController = TabController(length: tabs.length, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => MenuBloc()),
      ],
      child: Scaffold(
        body: TabBarView(
          physics: const NeverScrollableScrollPhysics(),
          controller: _tabController,
          children: tabs.values.toList(),
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.black,
          items: tabs.keys.toList(),
          currentIndex: _tabController.index,
          onTap: _onItemTapped,
          selectedItemColor: Colors.orange,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _tabController.index = index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
