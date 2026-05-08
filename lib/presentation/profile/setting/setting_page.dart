import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/routing.dart';
import 'package:pes_arena/core/theme/theme_provider.dart';

import '../../../firebase/auth/gn_auth.dart';
import '../bloc/profile_bloc.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (_) => getIt<ProfileBloc>(),
      child: const _SettingView(),
    );
  }
}

class _SettingView extends StatelessWidget {
  const _SettingView();

  @override
  Widget build(BuildContext context) {
    final auth = getIt<GNAuth>();
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Tuỳ chọn khác'),
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
            stops: const [0, 0.46, 1],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _SettingsHero(),
              const SizedBox(height: 16),
              _SettingsSection(
                children: [
                  _SettingActionTile(
                    icon: Icons.person_outline,
                    title: 'Cập nhật thông tin',
                    onTap: () => context.push(Routing.updateProfile),
                  ),
                  if (auth.isSignInWithEmailAndPassword)
                    _SettingActionTile(
                      icon: Icons.lock_outline,
                      title: 'Đổi mật khẩu',
                      onTap: () => context.push(Routing.changePassword),
                    ),
                  Builder(
                    builder: (context) {
                      final themeNotifier = context.watch<ThemeNotifier>();
                      return _SettingActionTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Chế độ tối',
                        trailing: Switch.adaptive(
                          value: themeNotifier.isDark,
                          onChanged: (value) {
                            themeNotifier.setTheme(
                              value ? ThemeMode.dark : ThemeMode.light,
                            );
                          },
                        ),
                        onTap: () {
                          themeNotifier.setTheme(
                            themeNotifier.isDark
                                ? ThemeMode.light
                                : ThemeMode.dark,
                          );
                        },
                      );
                    },
                  ),
                  _SettingActionTile(
                    icon: Icons.delete_outline,
                    title: 'Xoá tài khoản',
                    iconColor: colorScheme.error,
                    textColor: colorScheme.error,
                    showChevron: false,
                    onTap: () {
                      _deleteAccount(context, context.read<ProfileBloc>());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteAccount(BuildContext context, ProfileBloc profileBloc) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Xác nhận'),
          content: const Text(
            'Bạn có chắc chắn muốn xoá tài khoản không?\n\nTất cả dữ liệu cá nhân của bạn sẽ bị xoá và không thể khôi phục. Một số dữ liệu liên quan đến nhóm và các người chơi khác sẽ vẫn được giữ lại.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Huỷ'),
            ),
            TextButton(
              onPressed: () {
                profileBloc.add(DeleteProfileEvent());
                Navigator.of(context).pop();
              },
              child: Text(
                'Xoá tài khoản',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SettingsHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.tune_outlined, color: colorScheme.onSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preferences',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.secondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tuỳ chọn khác',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bảo mật, giao diện và tài khoản.',
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

class _SettingsSection extends StatelessWidget {
  final List<Widget> children;

  const _SettingsSection({required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.48)),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _SettingActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;
  final bool showChevron;

  const _SettingActionTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
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
              ?trailing,
              if (trailing == null && showChevron)
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
