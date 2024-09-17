import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/core/ultils.dart';

import 'bloc/tournament_detail_bloc.dart';
import 'matches/matches_view.dart';
import 'table/table_view.dart';

class TournamentDetailView extends StatefulWidget {
  const TournamentDetailView({Key? key}) : super(key: key);

  @override
  State<TournamentDetailView> createState() => _TournamentDetailViewState();
}

class _TournamentDetailViewState extends State<TournamentDetailView>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _tabController;

  final Map<Tab, Widget> tabs = {
    //const Tab(text: 'Tổng quan'): const EsportOverviewView(),
    const Tab(text: 'Trận đấu'): const EsportMatchesView(),
    const Tab(text: 'Bảng điểm'): const EsportTableView(),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: tabs.length,
      vsync: this,
      initialIndex: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocConsumer<TournamentDetailBloc, TournamentDetailState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Row(
            children: [
              SvgPicture.asset(
                'assets/svg/trophy-solid.svg',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Text(state.league.name),
              const SizedBox(width: 8),
              Expanded(
                child: TabBar(
                  controller: _tabController,
                  tabs: tabs.keys.toList(),
                  dividerHeight: 0,
                  // indicator: BoxDecoration(
                  //   color: Theme.of(context).secondaryHeaderColor,
                  //   borderRadius: BorderRadius.circular(40),
                  // ),
                  indicatorSize: TabBarIndicatorSize.label,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorPadding: const EdgeInsets.symmetric(horizontal: -16),
                  //padding: EdgeInsets.symmetric(horizontal: 8),
                ),
              )
            ],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: tabs.values.toList(),
            ),
            if (state.viewStatus.isLoading)
              const Positioned(
                  top: 0, right: 0, left: 0, child: LinearProgressIndicator()),
          ],
        ),
      ),
      listener: (context, state) {
        if (state.errorMessage.isNotEmpty) {
          showToast(state.errorMessage);
        }
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
