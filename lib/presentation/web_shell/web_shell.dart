import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class WebShell extends StatelessWidget {
  static const double mobileBreakpoint = 600;
  static const double frameWidth = 420;

  final Widget child;

  const WebShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth <= mobileBreakpoint) return child;
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: SizedBox(
              width: frameWidth,
              child: ClipRect(child: child),
            ),
          ),
        );
      },
    );
  }
}
