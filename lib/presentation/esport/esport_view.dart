import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/esport_bloc.dart';
import 'groups/groups_view.dart';
import 'tournament/tournament_view.dart';

class EsportView extends StatefulWidget {
  const EsportView({Key? key}) : super(key: key);

  @override
  State<EsportView> createState() => _EsportViewState();
}

class _EsportViewState extends State<EsportView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  Map<Tab, Widget> tabs = {};

  @override
  void initState() {
    super.initState();

    tabs = {
      const Tab(text: 'Giải đấu'): const TournamentView(),
      const Tab(text: 'Nhóm'): const GroupsView(),
    };
    _tabController =
        TabController(length: tabs.length, vsync: this, initialIndex: 0);
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
        backgroundColor: Colors.indigo[100],
        centerTitle: false,
        title: Row(
          children: [
            BlocBuilder<EsportBloc, EsportState>(
                builder: (context, state) => state.esportModel != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CachedNetworkImage(
                              imageUrl: state.esportModel!.image ?? '',
                              height: 32,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(state.esportModel!.name ?? '',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : const SizedBox.shrink()) /* const PesTitle()*/,
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
