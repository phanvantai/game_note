import 'package:flutter/material.dart';
import 'package:game_note/presentation/community/events/events_view.dart';
import 'package:game_note/presentation/community/home/home_view.dart';
import 'package:game_note/presentation/community/teams/teams_view.dart';

class CommunityView extends StatefulWidget {
  const CommunityView({Key? key}) : super(key: key);

  @override
  State<CommunityView> createState() => _CommunityViewState();
}

class _CommunityViewState extends State<CommunityView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  final Map<Tab, Widget> tabs = {
    const Tab(text: 'Trang chủ'): const HomeView(),
    const Tab(text: 'Sự kiện/Giải đấu'): const EventsView(),
    const Tab(text: 'Đội'): const TeamsView(),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: TabBar(
          controller: _tabController,
          tabs: tabs.keys.toList(),
          isScrollable: true,
          indicatorSize: TabBarIndicatorSize.tab,
          tabAlignment: TabAlignment.start,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            color: Theme.of(context).primaryColor.withOpacity(0.7),
          ),
          indicatorWeight: 0,
          labelColor: Colors.white,
          dividerHeight: 0,
          unselectedLabelColor: Colors.grey,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabs.values.toList(),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
