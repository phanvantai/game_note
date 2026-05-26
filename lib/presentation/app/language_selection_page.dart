import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/assets_path.dart';
import '../../core/localization/locale_notifier.dart';
import '../../l10n/l10n.dart';
import '../../routing.dart';

class LanguageSelectionPage extends StatefulWidget {
  const LanguageSelectionPage({super.key, this.nextLocation});

  final String? nextLocation;

  @override
  State<LanguageSelectionPage> createState() => _LanguageSelectionPageState();
}

class _LanguageSelectionPageState extends State<LanguageSelectionPage> {
  late Locale _selectedLocale;

  @override
  void initState() {
    super.initState();
    _selectedLocale = context
        .read<LocaleNotifier>()
        .initialSelectionFromDevice();
    if (kDebugMode) {
      debugPrint(
        '[LocaleFlow] LanguageSelectionPage.init: '
        'next=${widget.nextLocation} selected=${_selectedLocale.languageCode}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              shrinkWrap: true,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      AssetsPath.appIcon,
                      width: 84,
                      height: 84,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  l10n.languageTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.languageSubtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                _LanguageOption(
                  locale: const Locale('en'),
                  title: l10n.languageEnglish,
                  selected: _selectedLocale.languageCode == 'en',
                  suggested: _isSuggested(const Locale('en')),
                  onTap: () =>
                      setState(() => _selectedLocale = const Locale('en')),
                ),
                const SizedBox(height: 12),
                _LanguageOption(
                  locale: const Locale('vi'),
                  title: l10n.languageVietnamese,
                  selected: _selectedLocale.languageCode == 'vi',
                  suggested: _isSuggested(const Locale('vi')),
                  onTap: () =>
                      setState(() => _selectedLocale = const Locale('vi')),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  key: const ValueKey('language_continue_button'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.secondary,
                    foregroundColor: colorScheme.onSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _continue,
                  child: Text(l10n.continueButton),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isSuggested(Locale locale) {
    return context
            .read<LocaleNotifier>()
            .initialSelectionFromDevice()
            .languageCode ==
        locale.languageCode;
  }

  Future<void> _continue() async {
    await context.read<LocaleNotifier>().setLocale(_selectedLocale);
    if (!mounted) return;
    final target = Routing.safeNextLocation(widget.nextLocation);
    if (kDebugMode) {
      debugPrint(
        '[LocaleFlow] LanguageSelectionPage.continue: '
        'selected=${_selectedLocale.languageCode} '
        'next=${widget.nextLocation} target=$target',
      );
    }
    context.go(target);
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.locale,
    required this.title,
    required this.selected,
    required this.suggested,
    required this.onTap,
  });

  final Locale locale;
  final String title;
  final bool selected;
  final bool suggested;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedBackground = colorScheme.secondary.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.12,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          key: ValueKey('language_option_${locale.languageCode}'),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected
                ? selectedBackground
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? colorScheme.secondary
                  : colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            children: [
              Text(
                locale.languageCode.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected
                      ? colorScheme.secondary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (suggested) ...[
                      const SizedBox(height: 2),
                      Text(
                        context.l10n.languageSystemMatch,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? colorScheme.secondary : colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
