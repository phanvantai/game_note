import 'package:flutter/material.dart';
import 'package:game_note/features/community/presentation/community/community_view.dart';
import 'package:game_note/features/community/presentation/friends/friends_view.dart';
import 'package:game_note/presentation/profile/profile_page.dart';
import 'package:game_note/features/community/presentation/tournament/tournament_view.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with TickerProviderStateMixin {
  Map<BottomNavigationBarItem, Widget> tabs = const {
    BottomNavigationBarItem(
      icon: Icon(Icons.group),
      label: 'Cộng đồng',
    ): CommunityView(),
    BottomNavigationBarItem(
      icon: Icon(Icons.sports_score),
      label: 'Giải đấu',
    ): TournamentView(),
    BottomNavigationBarItem(
      icon: Icon(Icons.chat_bubble),
      label: 'Trò chuyện',
    ): FriendsView(),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Cá nhân',
    ): ProfilePage(),
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        items: tabs.keys.toList(),
        currentIndex: _tabController.index,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).unselectedWidgetColor,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        showUnselectedLabels: true,
        enableFeedback: true,
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
