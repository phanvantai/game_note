import 'package:flutter/material.dart';
import 'package:pes_arena/l10n/l10n.dart';

/// Plain page background used by the minimalist app shell.
class AppPageBackground extends StatelessWidget {
  final Widget child;

  const AppPageBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}

/// Bordered surface for content sections and dense data summaries.
class AppSectionSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  // coverage:ignore-start
  const AppSectionSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
  });
  // coverage:ignore-end

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      child: child,
    );
  }
}

/// Compact monochrome icon mark for headers and action rows.
class AppIconMark extends StatelessWidget {
  final IconData icon;
  final double size;

  // coverage:ignore-start
  const AppIconMark({super.key, required this.icon, this.size = 36});
  // coverage:ignore-end

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Icon(icon, size: size * 0.5, color: colorScheme.onSurface),
    );
  }
}

/// Standardized card wrapper with consistent styling.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  // coverage:ignore-start
  const AppCard({super.key, required this.child, this.padding, this.margin});
  // coverage:ignore-end

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline),
      ),
      child: padding != null ? Padding(padding: padding!, child: child) : child,
    );
  }
}

/// Centered empty state with icon, title, and optional subtitle.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  // coverage:ignore-start
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });
  // coverage:ignore-end

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 44,
              color: colorScheme.onSurface.withValues(alpha: 0.36),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standardized confirmation dialog.
Future<bool?> showAppConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String? cancelText,
  String? confirmText,
  bool isDestructive = false,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText ?? context.l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: isDestructive
                ? colorScheme.error
                : colorScheme.secondary,
            foregroundColor: isDestructive
                ? colorScheme.onError
                : colorScheme.onSecondary,
          ),
          child: Text(confirmText ?? context.l10n.commonConfirm),
        ),
      ],
    ),
  );
}

/// Standardized form dialog.
Future<T?> showAppFormDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  String? cancelText,
  String? submitText,
  VoidCallback? onSubmit,
}) {
  return showDialog<T>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(child: content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(cancelText ?? context.l10n.commonCancel),
        ),
        if (onSubmit != null)
          FilledButton(
            onPressed: onSubmit,
            child: Text(submitText ?? context.l10n.commonCreate),
          ),
      ],
    ),
  );
}

/// Auth-style input decoration.
InputDecoration appInputDecoration({
  required BuildContext context,
  String? hintText,
  String? labelText,
  IconData? prefixIcon,
  Widget? suffixIcon,
  String? errorText,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  return InputDecoration(
    hintText: hintText,
    labelText: labelText,
    hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.4)),
    prefixIcon: prefixIcon != null
        ? Icon(
            prefixIcon,
            color: colorScheme.onSurface.withValues(alpha: 0.56),
            size: 20,
          )
        : null,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: colorScheme.surfaceContainerHighest,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.outline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.outline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.error, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: colorScheme.error, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    errorText: errorText,
  );
}
