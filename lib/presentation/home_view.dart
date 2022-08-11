import 'package:flutter/material.dart';
import 'package:game_note/presentation/members_view.dart';
import 'package:game_note/presentation/solo_round/solo_round_view.dart';
import 'package:game_note/presentation/tournament_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  Map<BottomNavigationBarItem, Widget> tabs = const {
    BottomNavigationBarItem(
      icon: Icon(Icons.sports_soccer),
      label: 'Tournaments',
    ): TournamentView(),
    BottomNavigationBarItem(
      icon: Icon(Icons.sports_baseball),
      label: 'Solo',
    ): SoloRoundView(),
    BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Members',
    ): MembersView(),
  };
  late TabController _tabController;
  @override
  void initState() {
    _tabController = TabController(length: tabs.length, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _tabController,
        children: tabs.values.toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: tabs.keys.toList(),
        currentIndex: _tabController.index,
        onTap: _onItemTapped,
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
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
