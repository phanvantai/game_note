import 'package:flutter/material.dart';
import 'package:game_note/core/helpers/admob_helper.dart';
import 'package:game_note/firebase/messaging/gn_firebase_messaging.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
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
  BannerAd? _bannerAd;
  bool isAdsLoaded = false;

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

    getIt<GNFirebaseMessaging>().initialize();
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
          if (_bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
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
      adUnitId: AdmobHelper.bannerUnitIDHomeBottom,
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
