import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_repository.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/core/localization/locale_notifier.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/routing.dart';
import 'package:pes_arena/core/theme/theme_provider.dart';

import '../../../firebase/auth/gn_auth.dart';
import '../../common/smart_back.dart';
import '../bloc/profile_bloc.dart';
import 'ownership_resolution_page.dart';

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
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: const SmartBackButton(),
        title: Text(l10n.settingsTitle),
      ),
      body: AppPageBackground(
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
                    title: l10n.settingsUpdateProfile,
                    onTap: () => context.push(Routing.updateProfile),
                  ),
                  if (auth.isSignInWithEmailAndPassword)
                    _SettingActionTile(
                      icon: Icons.lock_outline,
                      title: l10n.settingsChangePassword,
                      onTap: () => context.push(Routing.changePassword),
                    ),
                  Builder(
                    builder: (context) {
                      final themeNotifier = context.watch<ThemeNotifier>();
                      return _SettingActionTile(
                        icon: Icons.dark_mode_outlined,
                        title: l10n.settingsDarkMode,
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
                    icon: Icons.language_outlined,
                    title: l10n.settingsLanguage,
                    trailing: Text(
                      _languageName(
                        context,
                        context.watch<LocaleNotifier>().currentLocale,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    onTap: () => _showLanguageSheet(context),
                  ),
                  _SettingActionTile(
                    icon: Icons.delete_outline,
                    title: l10n.settingsDeleteAccount,
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

  Future<void> _deleteAccount(
    BuildContext context,
    ProfileBloc profileBloc,
  ) async {
    final uid = getIt<GNAuth>().currentUser?.uid;
    if (uid == null) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final results = await Future.wait([
        getIt<EsportGroupRepository>().getGroupsByOwnerId(uid),
        getIt<EsportLeagueRepository>().getLeaguesByOwnerId(uid),
      ]);
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      final groups = results[0] as List;
      final leagues = results[1] as List;
      if (groups.isNotEmpty || leagues.isNotEmpty) {
        final resolved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => OwnershipResolutionPage(
              currentUserId: uid,
              groups: groups.cast(),
              leagues: leagues.cast(),
            ),
          ),
        );
        if (resolved == true && context.mounted) {
          profileBloc.add(DeleteProfileEvent());
        }
        return;
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.ownershipCheckFailed('$e'))),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: Text(context.l10n.settingsDeleteConfirmTitle),
          content: Text(context.l10n.settingsDeleteConfirmMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                profileBloc.add(DeleteProfileEvent());
                Navigator.of(context).pop();
              },
              child: Text(
                context.l10n.settingsDeleteAccount,
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

  String _languageName(BuildContext context, Locale? locale) {
    return switch (locale?.languageCode) {
      'vi' => context.l10n.languageVietnamese,
      _ => context.l10n.languageEnglish,
    };
  }

  void _showLanguageSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final localeNotifier = sheetContext.watch<LocaleNotifier>();
        final selected = localeNotifier.currentLocale ?? const Locale('en');
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(sheetContext.l10n.languageEnglish),
                trailing: selected.languageCode == 'en'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () async {
                  await sheetContext.read<LocaleNotifier>().setLocale(
                    const Locale('en'),
                  );
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
              ),
              ListTile(
                title: Text(sheetContext.l10n.languageVietnamese),
                trailing: selected.languageCode == 'vi'
                    ? const Icon(Icons.check)
                    : null,
                onTap: () async {
                  await sheetContext.read<LocaleNotifier>().setLocale(
                    const Locale('vi'),
                  );
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
              ),
            ],
          ),
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
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.tune_outlined,
            size: 24,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsHeroEyebrow,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.settingsTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.settingsHeroSubtitle,
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
    return Column(
      children: [
        for (var i = 0; i < children.length; i++) ...[
          children[i],
          if (i != children.length - 1) const SizedBox(height: 8),
        ],
      ],
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
