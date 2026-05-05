import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/remote_config/gn_remote_config.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:pes_arena/presentation/users/bloc/user_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/helpers/admob_helper.dart';
import '../../../users/user_item.dart';

class GroupDetailView extends StatefulWidget {
  const GroupDetailView({super.key});

  @override
  State<GroupDetailView> createState() => _GroupDetailViewState();
}

class _GroupDetailViewState extends State<GroupDetailView> {
  BannerAd? _bannerAd;
  bool isAdsLoaded = false;

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
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                if (state.viewStatus == ViewStatus.loading)
                  const LinearProgressIndicator(minHeight: 3),
                _GroupDetailHero(state: state),
                if (state.group.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _GroupSectionShell(
                    title: 'Mô tả',
                    icon: Icons.notes_outlined,
                    child: Text(
                      state.group.description,
                      style: textTheme.bodyMedium?.copyWith(height: 1.45),
                      textAlign: TextAlign.justify,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _GroupSectionShell(
                  title: 'Thành viên (${state.members.length})',
                  icon: Icons.people_alt_outlined,
                  trailing: state.isOwner
                      ? _RoleChip(
                          label: 'Owner',
                          icon: Icons.admin_panel_settings_outlined,
                          color: colorScheme.secondary,
                        )
                      : null,
                  child: Column(
                    children: state.members.asMap().entries.map((entry) {
                      final index = entry.key;
                      final user = entry.value;
                      final isLast = index == state.members.length - 1;
                      return Column(
                        children: [
                          _MemberTile(
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
                          ),
                          if (!isLast) const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
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
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
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

class _GroupDetailHero extends StatelessWidget {
  final GroupDetailState state;

  const _GroupDetailHero({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groupName = state.group.groupName.isEmpty
        ? 'Đang tải nhóm'
        : state.group.groupName;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.secondary.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.secondary.withValues(alpha: 0.18),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/images/pes_club_logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group arena',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  groupName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _HeroChip(
                      icon: Icons.people_alt_outlined,
                      label: '${state.members.length} thành viên',
                    ),
                    const SizedBox(width: 8),
                    if (state.isOwner)
                      _HeroChip(
                        icon: Icons.admin_panel_settings_outlined,
                        label: 'Quản trị',
                      )
                    else if (state.currentUserIsMember)
                      _HeroChip(
                        icon: Icons.verified_user_outlined,
                        label: 'Member',
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: colorScheme.secondary),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupSectionShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _GroupSectionShell({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.48)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
              ?trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
