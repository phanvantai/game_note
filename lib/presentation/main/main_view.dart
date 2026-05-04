import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/helpers/admob_helper.dart';
import 'package:pes_arena/firebase/messaging/gn_firebase_messaging.dart';
import 'package:pes_arena/firebase/remote_config/gn_remote_config.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../esport/groups/groups_view.dart';
import '../esport/tournament/tournament_view.dart';
import '../home/home_page.dart';
import '../notification/bloc/notification_bloc.dart';
import '../notification/notification_view.dart';
import '../profile/profile_view.dart';

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with TickerProviderStateMixin {
  BannerAd? _bannerAd;
  bool isAdsLoaded = false;

  late final List<_TabSpec> _tabs;

  late TabController _tabController;
  @override
  void initState() {
    super.initState();

    _tabs = const [
      _TabSpec(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Trang chủ',
        page: HomePage(),
      ),
      _TabSpec(
        icon: Icons.group_outlined,
        activeIcon: Icons.group,
        label: 'Nhóm',
        page: GroupsView(),
      ),
      _TabSpec(
        icon: Icons.emoji_events_outlined,
        activeIcon: Icons.emoji_events,
        label: 'Giải đấu',
        page: TournamentView(),
      ),
      _TabSpec(
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications,
        label: 'Thông báo',
        page: NotificationView(),
        showUnreadBadge: true,
      ),
      _TabSpec(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Cá nhân',
        page: ProfileView(),
      ),
    ];

    _tabController = TabController(length: _tabs.length, vsync: this);

    context.read<GroupBloc>().add(GetEsportGroups());

    if (!kIsWeb) {
      getIt<GNFirebaseMessaging>().initialize();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationBloc, NotificationState>(
      buildWhen: (prev, curr) =>
          prev.unreadNotificationsCount != curr.unreadNotificationsCount,
      builder: (context, notificationState) {
        return Scaffold(
          body: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: _tabController,
            children: _tabs.map((t) => t.page).toList(),
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
                type: BottomNavigationBarType.fixed,
                items: _tabs
                    .map(
                      (t) => BottomNavigationBarItem(
                        icon: _TabIcon(
                          icon: t.icon,
                          showBadge:
                              t.showUnreadBadge &&
                              notificationState.unreadNotificationsCount > 0,
                        ),
                        activeIcon: _TabIcon(
                          icon: t.activeIcon,
                          showBadge:
                              t.showUnreadBadge &&
                              notificationState.unreadNotificationsCount > 0,
                        ),
                        label: t.label,
                      ),
                    )
                    .toList(),
                currentIndex: _tabController.index,
                onTap: _onItemTapped,
              ),
            ],
          ),
        );
      },
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

class _TabSpec {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget page;
  final bool showUnreadBadge;

  const _TabSpec({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.page,
    this.showUnreadBadge = false,
  });
}

class _TabIcon extends StatelessWidget {
  final IconData icon;
  final bool showBadge;

  const _TabIcon({required this.icon, required this.showBadge});

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon);
    if (!showBadge) return iconWidget;
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        iconWidget,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.error,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}
