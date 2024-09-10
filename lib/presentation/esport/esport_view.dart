import 'package:flutter/material.dart';
import 'package:game_note/presentation/esport/groups/groups_view.dart';
import 'package:game_note/presentation/esport/tournament/tournament_page.dart';
import 'package:game_note/presentation/esport/widgets/pes_title.dart';

class EsportView extends StatefulWidget {
  const EsportView({Key? key}) : super(key: key);

  @override
  State<EsportView> createState() => _EsportViewState();
}

class _EsportViewState extends State<EsportView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  final Map<Tab, Widget> tabs = {
    const Tab(text: 'Giải đấu'): const TournamentPage(),
    const Tab(text: 'Nhóm'): const GroupsView(),
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
        centerTitle: false,
        title: Row(
          children: [
            const PesTitle(),
            Expanded(
              child: TabBar(
                dividerHeight: 0,
                controller: _tabController,
                tabs: tabs.keys.toList(),
                isScrollable: true,
                indicatorSize: TabBarIndicatorSize.label,
                tabAlignment: TabAlignment.start,
              ),
            )
          ],
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
