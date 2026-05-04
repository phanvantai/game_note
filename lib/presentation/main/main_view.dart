import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/helpers/admob_helper.dart';
import 'package:pes_arena/firebase/messaging/gn_firebase_messaging.dart';
import 'package:pes_arena/firebase/remote_config/gn_remote_config.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../esport/tournament/tournament_view.dart';
import '../home/home_page.dart';
import '../profile/profile_view.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with TickerProviderStateMixin {
  BannerAd? _bannerAd;
  bool isAdsLoaded = false;

  Map<BottomNavigationBarItem, Widget> tabs = {};

  late TabController _tabController;
  @override
  void initState() {
    super.initState();

    tabs = {
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Trang chủ',
      ): const HomePage(),
      const BottomNavigationBarItem(
        icon: Icon(Icons.emoji_events_outlined),
        activeIcon: Icon(Icons.emoji_events),
        label: 'Giải đấu',
      ): const TournamentView(),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Cá nhân',
      ): const ProfileView(),
    };

    _tabController = TabController(length: tabs.length, vsync: this);

    context.read<GroupBloc>().add(GetEsportGroups());

    if (!kIsWeb) {
      getIt<GNFirebaseMessaging>().initialize();
    }
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
          // coverage:ignore-start
          if (!kIsWeb && _bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
          // coverage:ignore-end
          BottomNavigationBar(
            items: tabs.keys.toList(),
            currentIndex: _tabController.index,
            onTap: _onItemTapped,
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
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  void _loadAd() async {
    if (kIsWeb || isAdsLoaded || !getIt<GNRemoteConfig>().adsEnabled) {
      return;
    }
    // coverage:ignore-start
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
          MediaQuery.of(context).size.width.truncate(),
        );
    _bannerAd = BannerAd(
      adUnitId: AdmobHelper.bannerUnitIDHomeBottom,
      request: const AdRequest(),
      size: size ?? AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            isAdsLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
        onAdOpened: (Ad ad) {
          debugPrint('on Ad Opened');
        },
        onAdClosed: (Ad ad) {
          debugPrint('on Ad Closed');
        },
        onAdImpression: (Ad ad) {
          debugPrint('on Ad Impression');
        },
      ),
    )..load();
    // coverage:ignore-end
  }
}
