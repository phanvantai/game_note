import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/features/community/community/community_view.dart';
import 'package:game_note/presentation/features/community/profile/profile_view.dart';
import 'package:game_note/presentation/features/community/tournament/tournament_view.dart';

import '../offline/menu/bloc/menu_bloc.dart';

class OnlineView extends StatefulWidget {
  const OnlineView({Key? key}) : super(key: key);

  @override
  State<OnlineView> createState() => _OnlineViewState();
}

class _OnlineViewState extends State<OnlineView> with TickerProviderStateMixin {
  Map<BottomNavigationBarItem, Widget> tabs = const {
    BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Community',
    ): CommunityView(),
    BottomNavigationBarItem(
      icon: Icon(Icons.sports_soccer),
      label: 'Tournaments',
    ): TournamentView(),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Profile',
    ): ProfileView(),
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
