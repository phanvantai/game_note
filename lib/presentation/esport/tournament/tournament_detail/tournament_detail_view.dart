import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/core/ultils.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/intl.dart';

import '../../../../core/helpers/admob_helper.dart';
import 'bloc/tournament_detail_bloc.dart';
import 'matches/matches_view.dart';
import 'setting/esport_league_setting.dart';
import 'table/table_view.dart';

class TournamentDetailView extends StatefulWidget {
  const TournamentDetailView({Key? key}) : super(key: key);

  @override
  State<TournamentDetailView> createState() => _TournamentDetailViewState();
}

class _TournamentDetailViewState extends State<TournamentDetailView>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  late TabController _tabController;

  Map<Tab, Widget> tabs = {};

  BannerAd? _bannerAd;
  bool isAdsLoaded = false;

  @override
  void initState() {
    super.initState();

    final leagueState = BlocProvider.of<TournamentDetailBloc>(context).state;
    // if user is admin, have advance permission, with other tabs
    tabs = {
      //const Tab(text: 'Tổng quan'): const EsportOverviewView(),
      const Tab(text: 'Trận đấu'): const EsportMatchesView(),
      const Tab(text: 'Bảng điểm'): const EsportTableView(),
      if (leagueState.currentUserIsLeagueAdmin)
        const Tab(text: 'Cài đặt'): const EsportLeagueSetting(),
    };
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

              Text(
                state.league?.name.isEmpty == true
                    ? ("${state.league?.group?.groupName ?? " "} ${DateFormat('dd/MM/yyyy').format(state.league?.startDate ?? DateTime.now())}")
                    : state.league?.name ?? '',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              //const SizedBox(width: 8),
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
                  //indicatorPadding: const EdgeInsets.symmetric(horizontal: -16),
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
        bottomNavigationBar: _bannerAd != null
            ? SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              )
            : null,
      ),
      listener: (context, state) {
        if (state.errorMessage.isNotEmpty) {
          showToast(state.errorMessage);
        }
        if (state.league != null && !state.league!.isActive) {
          showToast('Giải đấu đã kết thúc');
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _tabController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  /// Loads a banner ad.
  void _loadAd() async {
    if (isAdsLoaded) {
      return;
    }
    // Get an AnchoredAdaptiveBannerAdSize before loading the ad.
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            MediaQuery.of(context).size.width.truncate());
    _bannerAd = BannerAd(
      adUnitId: AdmobHelper.bannerUnitIDDetailBottom,
      request: const AdRequest(),
      size: size ?? AdSize.banner,
      listener: BannerAdListener(
        // Called when an ad is successfully received.
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            isAdsLoaded = true;
          });
        },
        // Called when an ad request failed.
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          // Dispose the ad here to free resources.
          ad.dispose();
        },
        // Called when an ad opens an overlay that covers the screen.
        onAdOpened: (Ad ad) {
          debugPrint('on Ad Opened');
        },
        // Called when an ad removes an overlay that covers the screen.
        onAdClosed: (Ad ad) {
          debugPrint('on Ad Closed');
        },
        // Called when an impression occurs on the ad.
        onAdImpression: (Ad ad) {
          debugPrint('on Ad Impression');
        },
      ),
    )..load();
  }
}
