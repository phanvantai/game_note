import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/presentation/app/bloc/app_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/common/app_info.dart';
import '../../core/common/view_status.dart';
import '../../core/constants/constants.dart';
import '../../core/ultils.dart';
import '../../routing.dart';
import 'bloc/profile_bloc.dart';
import 'feedback/feedback_view.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

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
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<ProfileBloc, ProfileState>(
      builder: (context, state) => Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              if (state.viewStatus == ViewStatus.loading)
                const LinearProgressIndicator(),
              const SizedBox(height: 24),
              // Avatar section
              Center(
                child: GestureDetector(
                  onTap: () => _showAvatarOptions(context),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: state.user?.photoUrl ?? '',
                        width: 96,
                        height: 96,
                        imageBuilder: (context, imageProvider) => CircleAvatar(
                          backgroundImage: imageProvider,
                          radius: 48,
                        ),
                        errorWidget: (context, url, error) => CircleAvatar(
                          radius: 48,
                          backgroundColor: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.person,
                            size: 40,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 14,
                            color: colorScheme.onSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Name + edit
              Center(
                child: state.displayUser.isNotEmpty
                    ? GestureDetector(
                        onTap: () => _navigateToUpdateProfile(context, state),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.displayUser,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: () => _navigateToUpdateProfile(context, state),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Vui lòng cập nhật thông tin',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 32),

              // Account section
              _buildSectionLabel(context, 'Tài khoản'),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.person_outline,
                      title: 'Cập nhật thông tin',
                      onTap: () =>
                          _navigateToUpdateProfile(context, state),
                    ),
                    Divider(
                        height: 0.5,
                        indent: 56,
                        color: colorScheme.outline.withValues(alpha: 0.2)),
                    _buildMenuItem(
                      context,
                      icon: Icons.lock_outline,
                      title: 'Đổi mật khẩu',
                      onTap: () => Navigator.of(context)
                          .pushNamed(Routing.changePassword),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // App section
              _buildSectionLabel(context, 'Ứng dụng'),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.wifi_off_outlined,
                      title: 'Chế độ offline',
                      onTap: () => _switchToOffline(context),
                    ),
                    Divider(
                        height: 0.5,
                        indent: 56,
                        color: colorScheme.outline.withValues(alpha: 0.2)),
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: 'Tuỳ chọn khác',
                      onTap: () => Navigator.of(context).pushNamed(
                          Routing.setting,
                          arguments: context.read<ProfileBloc>()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // About section
              _buildSectionLabel(context, 'Thông tin'),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.star_outline,
                      title: 'Đánh giá',
                      onTap: () {
                        Uri url;
                        if (Platform.isAndroid) {
                          url = Uri.parse(playStoreUrl);
                        } else {
                          url = Uri.parse(appStoreUrl);
                        }
                        launchUrl(url);
                      },
                    ),
                    Divider(
                        height: 0.5,
                        indent: 56,
                        color: colorScheme.outline.withValues(alpha: 0.2)),
                    _buildMenuItem(
                      context,
                      icon: Icons.chat_bubble_outline,
                      title: 'Nhận xét góp ý',
                      onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const FeedbackView())),
                    ),
                    Divider(
                        height: 0.5,
                        indent: 56,
                        color: colorScheme.outline.withValues(alpha: 0.2)),
                    ListTile(
                      onTap: _incrementCounter,
                      leading: Icon(
                        Icons.info_outline,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      title: Text('Phiên bản', style: textTheme.bodyLarge),
                      trailing: FutureBuilder<AppInfo>(
                        future: appInfo(),
                        builder: (context, snapshot) {
                          return Text(
                            snapshot.hasData
                                ? snapshot.data!.versionNumber
                                : '1.0.0',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Sign out
              AppCard(
                child: _buildMenuItem(
                  context,
                  icon: Icons.logout,
                  title: 'Đăng xuất',
                  iconColor: colorScheme.error,
                  textColor: colorScheme.error,
                  showChevron: false,
                  onTap: () => _signOut(context),
                ),
              ),
              const SizedBox(height: 32),
            ],
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

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool showChevron = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor,
            ),
      ),
      trailing: showChevron
          ? Icon(
              Icons.chevron_right,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            )
          : null,
      onTap: onTap,
    );
  }

  void _showAvatarOptions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Thay đổi ảnh đại diện'),
              onTap: () {
                context.read<ProfileBloc>().add(ChangeAvatarProfileEvent());
                Navigator.of(sheetContext).pop();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: colorScheme.error),
              title: Text(
                'Xoá ảnh đại diện',
                style: TextStyle(color: colorScheme.error),
              ),
              onTap: () {
                context.read<ProfileBloc>().add(DeleteAvatarProfileEvent());
                Navigator.of(sheetContext).pop();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _navigateToUpdateProfile(
      BuildContext context, ProfileState state) async {
    await Navigator.of(context)
        .pushNamed(Routing.updateProfile, arguments: state.user);
    if (mounted) {
      this.context.read<ProfileBloc>().add(LoadProfileEvent());
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
    if (confirmed == true && mounted) {
      Navigator.of(this.context).pushReplacementNamed(Routing.offline);
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
    if (confirmed == true && mounted) {
      this.context.read<ProfileBloc>().add(SignOutProfileEvent());
    }
  }

  @override
  bool get wantKeepAlive => true;
}
