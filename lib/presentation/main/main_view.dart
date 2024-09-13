import 'package:flutter/material.dart';
import 'package:game_note/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:provider/provider.dart';

//import '../community/community_view.dart';
import '../esport/esport_view.dart';
import '../notification/notification_view.dart';
import '../profile/profile_view.dart';
//import '../team/teams_view.dart';

class MainView extends StatefulWidget {
  const MainView({Key? key}) : super(key: key);

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with TickerProviderStateMixin {
  Map<BottomNavigationBarItem, Widget> tabs = const {
    // BottomNavigationBarItem(
    //   icon: Icon(Icons.sports_soccer),
    //   label: 'Cộng đồng',
    // ): CommunityView(),
    // BottomNavigationBarItem(
    //   icon: Icon(Icons.group),
    //   label: 'Đội',
    // ): TeamsView(),
    BottomNavigationBarItem(
      icon: Icon(Icons.sports_esports),
      label: 'Esport',
    ): EsportView(),
    BottomNavigationBarItem(
      icon: Icon(Icons.notifications),
      label: 'Thông báo',
    ): NotificationView(),
    BottomNavigationBarItem(
      icon: Icon(Icons.person),
      label: 'Cá nhân',
    ): ProfileView(),
  };

  late TabController _tabController;
  @override
  void initState() {
    _tabController = TabController(length: tabs.length, vsync: this);
    super.initState();

    context.read<GroupBloc>().add(GetEsportGroups());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _tabController,
        children: tabs.values.toList(),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: double.maxFinite, height: 0),
          BottomNavigationBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            items: tabs.keys.toList(),
            currentIndex: _tabController.index,
            onTap: _onItemTapped,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Theme.of(context).unselectedWidgetColor,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            showUnselectedLabels: true,
            enableFeedback: true,
            type: BottomNavigationBarType.fixed,
          ),
        ],
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
