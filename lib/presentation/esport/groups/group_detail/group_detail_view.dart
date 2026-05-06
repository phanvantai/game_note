import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/remote_config/gn_remote_config.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
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
      _leaguesLoaded = true;
      final groupId = context.read<GroupDetailBloc>().state.group.id;
      context.read<GroupDetailBloc>()
        ..add(LoadGroupOverview(groupId))
        ..add(LoadGroupLeagues(groupId));
    });
  }

  void _onTabChanged() {
    final groupId = context.read<GroupDetailBloc>().state.group.id;
    if (_tabController.index == 0 && !_overviewLoaded) {
      _overviewLoaded = true;
      _leaguesLoaded = true;
      context.read<GroupDetailBloc>()
        ..add(LoadGroupOverview(groupId))
        ..add(LoadGroupLeagues(groupId));
    }
    if (_tabController.index == 2 && !_leaguesLoaded) {
      _leaguesLoaded = true;
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
          actions: [
            if (state.currentUserIsMember && !state.isOwner)
              PopupMenuButton<_GroupAction>(
                onSelected: (action) {
                  if (action == _GroupAction.leaveGroup &&
                      state.currentUserId != null) {
                    _removeMember(true, context, state, state.currentUserId!);
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: _GroupAction.leaveGroup,
                    child: Row(
                      children: [
                        Icon(
                          Icons.exit_to_app,
                          color: colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Rời nhóm',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
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
            child: Column(
              children: [
                _GroupDetailTabBar(controller: _tabController),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      const GroupOverviewTab(),
                      _MembersTab(
                        state: state,
                        onAddMember: () => _addMember(context, state),
                        onRemoveMember: (userId) =>
                            _removeMember(false, context, state, userId),
                      ),
                      const GroupLeaguesTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
    context.push(
      '/group/${state.group.id}/add-member',
      extra: {
        'bloc': context.read<GroupDetailBloc>(),
        'members': Set<String>.from(state.group.members),
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

class _GroupDetailTabBar extends StatelessWidget {
  final TabController controller;

  const _GroupDetailTabBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 46,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.42)),
      ),
      child: TabBar(
        controller: controller,
        padding: EdgeInsets.zero,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colorScheme.secondary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: colorScheme.onSecondary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        labelStyle: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
        tabs: const [
          Tab(text: 'Tổng quan'),
          Tab(text: 'Thành viên'),
          Tab(text: 'Giải đấu'),
        ],
      ),
    );
  }
}

class _MembersTab extends StatelessWidget {
  final GroupDetailState state;
  final VoidCallback onAddMember;
  final void Function(String userId) onRemoveMember;

  const _MembersTab({
    required this.state,
    required this.onAddMember,
    required this.onRemoveMember,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomScrollView(
      slivers: [
        if (state.isOwner)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: FilledButton.icon(
                onPressed: onAddMember,
                icon: const Icon(Icons.person_add_outlined, size: 18),
                label: const Text('Thêm thành viên'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ),
          ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, state.isOwner ? 8 : 12, 16, 96),
          sliver: SliverList.separated(
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemCount: state.members.length,
            itemBuilder: (_, index) {
              final user = state.members[index];
              return _MemberTile(
                child: UserItem(
                  user: user,
                  trailing: state.isOwner
                      ? !user.isCurrentUser
                            ? IconButton(
                                tooltip: 'Xoá thành viên',
                                onPressed: () => onRemoveMember(user.id),
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
        ),
      ],
    );
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

enum _GroupAction { leaveGroup }
