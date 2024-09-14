import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    const Tab(text: 'Lịch thi đấu'): const EsportMatchesView(),
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
          title: ListTile(
            leading: Padding(
              padding: const EdgeInsets.only(left: 32),
              child: SvgPicture.asset(
                'assets/svg/trophy-solid.svg',
                width: 24,
                height: 24,
              ),
            ),
            title: Text(state.league.name),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: tabs.keys.toList(),
            dividerHeight: 0,
            indicator: BoxDecoration(
              color: Theme.of(context).secondaryHeaderColor,
              borderRadius: BorderRadius.circular(40),
            ),
            indicatorSize: TabBarIndicatorSize.label,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorPadding: const EdgeInsets.symmetric(horizontal: -16),
            //padding: EdgeInsets.symmetric(horizontal: 8),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: tabs.values.toList(),
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
