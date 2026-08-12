import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/l10n/l10n.dart';
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
        body: AppPageBackground(
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
                  title: context.l10n.profileAppSection,
                  icon: Icons.tune_outlined,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.settings_outlined,
                      title: context.l10n.profileOtherOptions,
                      onTap: () => context.push(Routing.setting),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: context.l10n.profileInfoSection,
                  icon: Icons.info_outline,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.star_outline,
                      title: context.l10n.profileRateApp,
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
                      title: context.l10n.profileFeedback,
                      onTap: () => context.push(Routing.feedback),
                    ),
                    _VersionMenuItem(onTap: _incrementCounter),
                  ],
                ),
                const SizedBox(height: 16),
                _ProfileSection(
                  title: context.l10n.profileSessionSection,
                  icon: Icons.logout,
                  children: [
                    _buildMenuItem(
                      context,
                      icon: Icons.logout,
                      title: context.l10n.profileSignOut,
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
                title: context.l10n.profileChangeAvatar,
                onTap: () {
                  context.read<ProfileBloc>().add(ChangeAvatarProfileEvent());
                  Navigator.of(sheetContext).pop();
                },
              ),
              const SizedBox(height: 8),
              _SheetAction(
                icon: Icons.delete_outline,
                title: context.l10n.profileDeleteAvatar,
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

  void _signOut(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: context.l10n.profileSignOut,
      message: context.l10n.profileSignOutMessage,
      confirmText: context.l10n.profileSignOut,
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
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
                        color: colorScheme.onSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 13,
                        color: colorScheme.surface,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: GestureDetector(
              onTap: onEditTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Player profile',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
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
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            color: colorScheme.onSurfaceVariant,
            onPressed: onEditTap,
            iconSize: 18,
            tooltip: context.l10n.profileEditTooltip,
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 2),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
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
    final resolvedIconColor = iconColor ?? colorScheme.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, color: resolvedIconColor, size: 20),
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: colorScheme.onSurfaceVariant,
                size: 20,
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
