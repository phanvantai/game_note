import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:pes_arena/presentation/users/bloc/user_bloc.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../../core/helpers/admob_helper.dart';
import '../../../users/user_item.dart';

class GroupDetailView extends StatefulWidget {
  const GroupDetailView({Key? key}) : super(key: key);

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
        appBar: AppBar(
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/pes_club_logo.png',
                  width: 32,
                  height: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.group.groupName,
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (state.viewStatus == ViewStatus.loading)
              const LinearProgressIndicator(),
            // Description card
            if (state.group.description.isNotEmpty) ...[
              _buildSectionLabel(context, 'Mô tả'),
              const SizedBox(height: 8),
              AppCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Text(
                  state.group.description,
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.justify,
                ),
              ),
              const SizedBox(height: 20),
            ],
            // Location card
            _buildSectionLabel(context, 'Khu vực'),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 20,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(state.group.location, style: textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Members card
            _buildSectionLabel(context, 'Thành viên (${state.members.length})'),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                children: state.members.asMap().entries.map((entry) {
                  final index = entry.key;
                  final user = entry.value;
                  final isLast = index == state.members.length - 1;
                  return Column(
                    children: [
                      UserItem(
                        user: user,
                        trailing: state.isOwner
                            ? !user.isCurrentUser
                                ? IconButton(
                                    onPressed: () => _removeMember(
                                        false, context, state, user.id),
                                    icon: Icon(
                                      Icons.person_remove_outlined,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.4),
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
                      if (!isLast)
                        Divider(
                          height: 0.5,
                          indent: 56,
                          color: colorScheme.outline.withValues(alpha: 0.15),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
        floatingActionButton: _floatingButton(context, state),
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
      },
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.45),
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
      ),
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

  void _loadAd() async {
    if (isAdsLoaded) return;
    final AnchoredAdaptiveBannerAdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
            MediaQuery.of(context).size.width.truncate());
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
                          BlocProvider.of<GroupDetailBloc>(context).add(
                            AddMember(state.group.id, user.id),
                          );
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

  void _removeMember(bool currentUser, BuildContext context,
      GroupDetailState state, String userId) async {
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
      BlocProvider.of<GroupDetailBloc>(context).add(
        RemoveMember(state.group.id, userId),
      );
    }
  }
}
