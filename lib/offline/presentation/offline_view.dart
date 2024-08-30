import 'package:flutter/material.dart';

import 'league/league_page.dart';
import 'members/members_view.dart';
import 'menu_view.dart';
import 'statistic/statistic_view.dart';

class OfflineView extends StatefulWidget {
  const OfflineView({Key? key}) : super(key: key);

  @override
  State<OfflineView> createState() => _OfflineViewState();
}

class _OfflineViewState extends State<OfflineView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  Map<BottomNavigationBarItem, Widget> tabs = const {
    BottomNavigationBarItem(
      icon: Icon(Icons.sports_soccer),
      label: 'Giải đấu',
    ): LeaguePage(),
    BottomNavigationBarItem(
      icon: Icon(Icons.view_column),
      label: 'Thống kê',
    ): StatisticView(),
    BottomNavigationBarItem(
      icon: Icon(Icons.people),
      label: 'Người chơi',
    ): MembersView(),
    BottomNavigationBarItem(
      icon: Icon(Icons.menu),
      label: 'Khác',
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
    super.build(context);
    return Scaffold(
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
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
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

  @override
  bool get wantKeepAlive => true;
}
