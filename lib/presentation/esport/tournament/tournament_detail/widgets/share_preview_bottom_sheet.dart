import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:share_plus/share_plus.dart';

// coverage:ignore-start
@visibleForTesting
Future<ShareResult> Function(ShareParams params) sharePreviewShare =
    SharePlus.instance.share;
// coverage:ignore-end

@visibleForTesting
Future<File> Function(Uint8List imageBytes) sharePreviewWriteFile =
    _writeSharePreviewFile;

Future<File> _writeSharePreviewFile(Uint8List imageBytes) async {
  final tempDir = Directory.systemTemp;
  final file = File('${tempDir.path}/league_standings.png');
  await file.writeAsBytes(imageBytes);
  return file;
}

Future<void> showSharePreviewBottomSheet({
  required BuildContext context,
  required Uint8List darkImageBytes,
  required Uint8List lightImageBytes,
  required String leagueName,
  Uint8List? darkCostImageBytes,
  Uint8List? lightCostImageBytes,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _SharePreviewSheet(
      darkImageBytes: darkImageBytes,
      lightImageBytes: lightImageBytes,
      leagueName: leagueName,
      darkCostImageBytes: darkCostImageBytes,
      lightCostImageBytes: lightCostImageBytes,
    ),
  );
}

class _SharePreviewSheet extends StatefulWidget {
  final Uint8List darkImageBytes;
  final Uint8List lightImageBytes;
  final String leagueName;
  final Uint8List? darkCostImageBytes;
  final Uint8List? lightCostImageBytes;

  const _SharePreviewSheet({
    required this.darkImageBytes,
    required this.lightImageBytes,
    required this.leagueName,
    this.darkCostImageBytes,
    this.lightCostImageBytes,
  });

  @override
  State<_SharePreviewSheet> createState() => _SharePreviewSheetState();
}

class _SharePreviewSheetState extends State<_SharePreviewSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _sharing = false;
  bool _isDark = false;
  bool _includeCost = false;
  bool _themeInitialized = false;

  bool get _canIncludeCost =>
      widget.darkCostImageBytes != null && widget.lightCostImageBytes != null;

  Uint8List get _activeImage {
    if (_includeCost && _canIncludeCost) {
      return _isDark ? widget.darkCostImageBytes! : widget.lightCostImageBytes!;
    }
    return _isDark ? widget.darkImageBytes : widget.lightImageBytes;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_themeInitialized) {
      _themeInitialized = true;
      _isDark = Theme.of(context).brightness == Brightness.dark;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _doShare() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    final box = context.findRenderObject() as RenderBox?;
    final originRect = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final shareTitle = context.l10n.tournamentShareStandingsTitle(
      widget.leagueName,
    );
    try {
      final file = await sharePreviewWriteFile(_activeImage);
      await sharePreviewShare(
        ShareParams(
          title: shareTitle,
          files: [XFile(file.path)],
          sharePositionOrigin: originRect,
        ),
      );
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom:
            MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title row + theme toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.share_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.tournamentShareStandingsSheetTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                _ThemeToggle(
                  isDark: _isDark,
                  onChanged: (v) => setState(() => _isDark = v),
                ),
              ],
            ),
          ),

          if (_canIncludeCost) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _CostToggle(
                value: _includeCost,
                onChanged: (value) => setState(() => _includeCost = value),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Preview image with crossfade
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ScaleTransition(
              scale: _scaleAnim,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: screenHeight * 0.52),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: SingleChildScrollView(
                      key: ValueKey('$_isDark-$_includeCost'),
                      physics: const BouncingScrollPhysics(),
                      child: Image.memory(_activeImage, fit: BoxFit.fitWidth),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(context.l10n.groupClose),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _sharing ? null : _doShare,
                    icon: _sharing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.share_rounded, size: 20),
                    label: Text(
                      _sharing
                          ? context.l10n.tournamentPreparingShare
                          : context.l10n.tournamentShareNow,
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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

class _CostToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _CostToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.payments_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context.l10n.tournamentShareIncludeRankCost,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const _ThemeToggle({required this.isDark, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleOption(
            icon: Icons.light_mode_outlined,
            label: context.l10n.tournamentLightTheme,
            selected: !isDark,
            onTap: () => onChanged(false),
          ),
          _ToggleOption(
            icon: Icons.dark_mode_outlined,
            label: context.l10n.tournamentDarkTheme,
            selected: isDark,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.all(3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? colorScheme.secondary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected
                  ? colorScheme.onSecondary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected
                    ? colorScheme.onSecondary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
