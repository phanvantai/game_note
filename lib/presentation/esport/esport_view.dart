import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:game_note/firebase/firestore/esport/gn_firestore_esport.dart';
import 'package:game_note/firebase/firestore/gn_firestore.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/esport/groups/groups_view.dart';
import 'package:game_note/presentation/esport/tournament/tournament_page.dart';

import '../../firebase/firestore/esport/esport_model.dart';

class EsportView extends StatefulWidget {
  const EsportView({Key? key}) : super(key: key);

  @override
  State<EsportView> createState() => _EsportViewState();
}

class _EsportViewState extends State<EsportView>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;

  final Map<Tab, Widget> tabs = {
    const Tab(text: 'Sự kiện/Giải đấu'): const TournamentPage(),
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
        title: FutureBuilder<List<EsportModel>>(
            future: getIt<GNFirestore>().getEsports(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const SizedBox.shrink();
              }
              if (snapshot.hasData) {
                if (snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: snapshot.data!.first.image ?? '',
                        height: 32,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(snapshot.data!.first.name ?? '',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                );
              }
              return const SizedBox.shrink();
            }),
        bottom: TabBar(
          controller: _tabController,
          tabs: tabs.keys.toList(),
          isScrollable: true,
          indicatorSize: TabBarIndicatorSize.tab,
          tabAlignment: TabAlignment.start,
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
