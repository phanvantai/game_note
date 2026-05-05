import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/presentation/app/bloc/app_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/common/app_info.dart';
import '../../core/common/view_status.dart';
import '../../core/constants/constants.dart';
import '../../core/ultils.dart';
import '../../routing.dart';
import 'bloc/profile_bloc.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with AutomaticKeepAliveClientMixin {
  int _counter = 0;

  void _incrementCounter() {
    final appBloc = context.read<AppBloc>();

    setState(() {
      if (!appBloc.state.enableFootballFeature) {
        _counter++;
      } else {
        _counter--;
      }
    });
    if (_counter == 10) {
      context.read<AppBloc>().add(const UpdateFootballFeature(true));
    }
    if (_counter == -10) {
      context.read<AppBloc>().add(const UpdateFootballFeature(false));
    }
  }

  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(LoadProfileEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = Theme.of(context).colorScheme;

    return BlocConsumer<ProfileBloc, ProfileState>(
      builder: (context, state) => Scaffold(
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
              stops: const [0, 0.46, 1],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              children: [
                if (state.viewStatus == ViewStatus.loading)
                  const LinearProgressIndicator(minHeight: 3),
                _ProfileHero(
                  state: state,
                  onAvatarTap: kIsWeb
                      ? null
                      : () => _showAvatarOptions(context),
                  onEditTap: () => _navigateToUpdateProfile(context, state),
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Tài khoản',
                  icon: Icons.manage_accounts_outlined,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.person_outline,
                      title: 'Cập nhật thông tin',
                      onTap: () => _navigateToUpdateProfile(context, state),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.lock_outline,
                      title: 'Đổi mật khẩu',
                      onTap: () => context.push(Routing.changePassword),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Ứng dụng',
                  icon: Icons.tune_outlined,
                  children: [
                    if (!kIsWeb) ...[
                      _buildMenuItem(
                        context,
                        icon: Icons.wifi_off_outlined,
                        title: 'Chế độ offline',
                        onTap: () => _switchToOffline(context),
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.sync_outlined,
                        title: 'Đồng bộ dữ liệu offline',
                        onTap: () => context.push(Routing.syncOfflineData),
                      ),
                    ],
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Tuỳ chọn khác',
                      onTap: () => context.push(Routing.setting),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Thông tin',
                  icon: Icons.info_outline,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.star_outline,
                      title: 'Đánh giá',
                      onTap: () {
                        final url =
                            defaultTargetPlatform == TargetPlatform.android
                            ? Uri.parse(playStoreUrl)
                            : Uri.parse(appStoreUrl);
                        launchUrl(url);
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.chat_bubble_outline,
                      title: 'Nhận xét góp ý',
                      onTap: () => context.push(Routing.feedback),
                    ),
                    _VersionMenuItem(onTap: _incrementCounter),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: 'Phiên làm việc',
                  icon: Icons.logout,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      title: 'Đăng xuất',
                      iconColor: colorScheme.error,
                      textColor: colorScheme.error,
                      showChevron: false,
                      onTap: () => _signOut(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      listener: (context, state) {
        if (state.error.isNotEmpty) {
          showSnackBar(context, state.error);
        }
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool showChevron = true,
  }) {
    return _ProfileActionTile(
      icon: icon,
      title: title,
      iconColor: iconColor,
      textColor: textColor,
      showChevron: showChevron,
      onTap: onTap,
    );
  }

  void _showAvatarOptions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              _SheetAction(
                icon: Icons.image_outlined,
                title: 'Thay đổi ảnh đại diện',
                onTap: () {
                  context.read<ProfileBloc>().add(ChangeAvatarProfileEvent());
                  Navigator.of(sheetContext).pop();
                },
              ),
              const SizedBox(height: 8),
              _SheetAction(
                icon: Icons.delete_outline,
                title: 'Xoá ảnh đại diện',
                color: colorScheme.error,
                onTap: () {
                  context.read<ProfileBloc>().add(DeleteAvatarProfileEvent());
                  Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToUpdateProfile(
    BuildContext context,
    ProfileState state,
  ) async {
    await context.push(Routing.updateProfile, extra: state.user);
    if (context.mounted) {
      context.read<ProfileBloc>().add(LoadProfileEvent());
    }
  }

  void _switchToOffline(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Chế độ Offline',
      message:
          'Chế độ offline là bạn tự tạo dữ liệu trên máy và dữ liệu sẽ chỉ được lưu trên máy của bạn, không được đồng bộ.\n\nBạn có chắc chắn muốn chuyển sang chế độ offline không?',
      confirmText: 'Chấp nhận',
    );
    if (confirmed == true && context.mounted) {
      context.go(Routing.offline);
    }
  }

  void _signOut(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: 'Đăng xuất',
      message: 'Bạn có chắc chắn muốn đăng xuất không?',
      confirmText: 'Đăng xuất',
      isDestructive: true,
    );
    if (confirmed == true && context.mounted) {
      context.read<ProfileBloc>().add(SignOutProfileEvent());
    }
  }

  @override
  bool get wantKeepAlive => true;
}

class _ProfileHero extends StatelessWidget {
  final ProfileState state;
  final VoidCallback? onAvatarTap;
  final VoidCallback onEditTap;

  const _ProfileHero({
    required this.state,
    required this.onAvatarTap,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final display = state.displayUser.isEmpty
        ? 'Vui lòng cập nhật thông tin'
        : state.displayUser;
    final contact = state.user?.email ?? state.user?.phoneNumber ?? 'PES Arena';

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
          GestureDetector(
            onTap: onAvatarTap,
            child: Stack(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: colorScheme.secondary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CachedNetworkImage(
                      imageUrl: state.user?.photoUrl ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.person,
                          size: 34,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                if (onAvatarTap != null)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: colorScheme.surface,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 13,
                        color: colorScheme.onSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Player profile',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  display,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contact,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _ProfileSection({
    required this.title,
    required this.icon,
    required this.children,
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
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final bool showChevron;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolvedIconColor = iconColor ?? colorScheme.secondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.26),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: resolvedIconColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: resolvedIconColor, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (showChevron)
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VersionMenuItem extends StatelessWidget {
  final VoidCallback onTap;

  const _VersionMenuItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.26),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: colorScheme.secondary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Phiên bản',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FutureBuilder<AppInfo>(
                future: appInfo(),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.hasData ? snapshot.data!.versionNumber : '1.0.0',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  const _SheetAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedColor = color ?? colorScheme.secondary;
    return _ProfileActionTile(
      icon: icon,
      title: title,
      iconColor: resolvedColor,
      textColor: color,
      showChevron: false,
      onTap: onTap,
    );
  }
}
