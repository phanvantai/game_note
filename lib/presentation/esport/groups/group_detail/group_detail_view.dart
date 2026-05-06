import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/remote_config/gn_remote_config.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:pes_arena/presentation/users/bloc/user_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/helpers/admob_helper.dart';
import '../../../users/user_item.dart';
import 'widgets/group_leagues_tab.dart';
import 'widgets/group_overview_tab.dart';

class GroupDetailView extends StatefulWidget {
  const GroupDetailView({super.key});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView>
    with SingleTickerProviderStateMixin {
  BannerAd? _bannerAd;
  bool isAdsLoaded = false;
  late final TabController _tabController;
  bool _leaguesLoaded = false;
  bool _overviewLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _overviewLoaded) return;
      _overviewLoaded = true;
      final groupId = context.read<GroupDetailBloc>().state.group.id;
      context.read<GroupDetailBloc>().add(LoadGroupOverview(groupId));
    });
  }

  void _onTabChanged() {
    if (_tabController.index == 0 && !_overviewLoaded) {
      _overviewLoaded = true;
      final groupId = context.read<GroupDetailBloc>().state.group.id;
      context.read<GroupDetailBloc>().add(LoadGroupOverview(groupId));
    }
    if (_tabController.index == 2 && !_leaguesLoaded) {
      _leaguesLoaded = true;
      final groupId = context.read<GroupDetailBloc>().state.group.id;
      context.read<GroupDetailBloc>().add(LoadGroupLeagues(groupId));
    }
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(_onTabChanged)
      ..dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<GroupDetailBloc, GroupDetailState>(
      builder: (context, state) => Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            state.group.groupName.isEmpty
                ? 'Chi tiết nhóm'
                : state.group.groupName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Tổng quan'),
              Tab(text: 'Thành viên'),
              Tab(text: 'Giải đấu'),
            ],
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.secondary.withValues(alpha: 0.16),
                Theme.of(context).scaffoldBackgroundColor,
                colorScheme.primary.withValues(alpha: 0.06),
              ],
              stops: const [0, 0.48, 1],
            ),
          ),
          child: SafeArea(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Tổng quan
                const GroupOverviewTab(),
                // Tab 2: Thành viên — list only, hero + description live
                // on the Tổng quan tab now.
                ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                  itemCount: state.members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, index) {
                    final user = state.members[index];
                    return _MemberTile(
                      child: UserItem(
                        user: user,
                        trailing: state.isOwner
                            ? !user.isCurrentUser
                                ? IconButton(
                                    tooltip: 'Xoá thành viên',
                                    onPressed: () => _removeMember(
                                      false,
                                      context,
                                      state,
                                      user.id,
                                    ),
                                    icon: Icon(
                                      Icons.person_remove_outlined,
                                      color: colorScheme.error,
                                      size: 20,
                                    ),
                                  )
                                : Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: colorScheme.secondary,
                                    size: 20,
                                  )
                            : user.id == state.group.ownerId
                                ? Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: colorScheme.secondary,
                                    size: 20,
                                  )
                                : null,
                      ),
                    );
                  },
                ),
                // Tab 3: Giải đấu
                const GroupLeaguesTab(),
              ],
            ),
          ),
        ),
        floatingActionButton: _floatingButton(context, state),
        bottomNavigationBar: (!kIsWeb && _bannerAd != null)
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
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  Widget? _floatingButton(BuildContext context, GroupDetailState state) {
    if (state.isOwner) {
      return FloatingActionButton.extended(
        onPressed: () => _addMember(context, state),
        label: const Text('Thêm thành viên'),
        icon: const Icon(Icons.person_add_outlined),
      );
    }
    if (state.currentUserIsMember) {
      return FloatingActionButton.extended(
        onPressed: () {
          if (state.currentUserId != null) {
            _removeMember(true, context, state, state.currentUserId!);
          }
        },
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
        label: const Text('Rời nhóm'),
        icon: const Icon(Icons.exit_to_app),
      );
    }
    return null;
  }

  void _loadAd() async {
    if (kIsWeb || isAdsLoaded || !getIt<GNRemoteConfig>().adsEnabled) return;
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
          MediaQuery.of(context).size.width.truncate(),
        );
    _bannerAd = BannerAd(
      adUnitId: AdmobHelper.bannerUnitIDDetailBottom,
      request: const AdRequest(),
      size: size ?? AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() => isAdsLoaded = true);
        },
        onAdFailedToLoad: (ad, err) {
          debugPrint('BannerAd failed to load: $err');
          ad.dispose();
        },
        onAdOpened: (Ad ad) => debugPrint('on Ad Opened'),
        onAdClosed: (Ad ad) => debugPrint('on Ad Closed'),
        onAdImpression: (Ad ad) => debugPrint('on Ad Impression'),
      ),
    )..load();
  }

  void _addMember(BuildContext context, GroupDetailState state) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final userBloc = getIt<UserBloc>();
        return BlocBuilder<UserBloc, UserState>(
          bloc: userBloc..add(const SearchUser('')),
          builder: (userContext, userState) => AlertDialog(
            title: const Text('Thêm thành viên'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: appInputDecoration(
                    context: context,
                    hintText: 'Tìm kiếm theo tên',
                    prefixIcon: Icons.search,
                  ),
                  onChanged: (value) => userBloc.add(SearchUser(value)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 250,
                  width: double.maxFinite,
                  child: ListView.builder(
                    itemCount: userState.users.length,
                    itemBuilder: (ctx, index) {
                      final user = userState.users[index];
                      if (user.isCurrentUser ||
                          state.group.members.contains(user.id)) {
                        return const SizedBox.shrink();
                      }
                      return UserItem(
                        user: user,
                        onTap: () {
                          BlocProvider.of<GroupDetailBloc>(
                            context,
                          ).add(AddMember(state.group.id, user.id));
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Đóng'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _removeMember(
    bool currentUser,
    BuildContext context,
    GroupDetailState state,
    String userId,
  ) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: currentUser ? 'Rời nhóm' : 'Xóa thành viên',
      message: currentUser
          ? 'Bạn có chắc chắn muốn rời nhóm?'
          : 'Bạn có chắc chắn muốn xóa thành viên này không?',
      confirmText: currentUser ? 'Rời nhóm' : 'Xóa',
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      BlocProvider.of<GroupDetailBloc>(
        context,
      ).add(RemoveMember(state.group.id, userId));
    }
  }
}

class _MemberTile extends StatelessWidget {
  final Widget child;

  const _MemberTile({required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.28)),
      ),
      child: child,
    );
  }
}
