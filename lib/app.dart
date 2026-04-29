import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'presentation/web_shell/web_shell.dart';
import 'routing.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, _) {
        return MaterialApp.router(
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeNotifier.themeMode,
          builder: (context, child) {
            final shell = WebShell(child: child ?? const SizedBox.shrink());
            if (!kIsWeb) return shell;
            return Stack(
              children: [
                shell,
                const Positioned(top: 0, left: 0, right: 0, child: _RouterUriBanner()),
              ],
            );
          },
        );
      },
    );
  }
}

class _RouterUriBanner extends StatefulWidget {
  const _RouterUriBanner();

  @override
  State<_RouterUriBanner> createState() => _RouterUriBannerState();
}

class _RouterUriBannerState extends State<_RouterUriBanner> {
  String _uri = '';
  int _delegateTicks = 0;

  @override
  void initState() {
    super.initState();
    appRouter.routerDelegate.addListener(_update);
    _update();
  }

  @override
  void dispose() {
    appRouter.routerDelegate.removeListener(_update);
    super.dispose();
  }

  void _update() {
    _delegateTicks++;
    final next = appRouter.routerDelegate.currentConfiguration.uri.toString();
    debugPrint('[router] tick=$_delegateTicks uri=$next');
    if (mounted) setState(() => _uri = next);
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Material(
        color: Colors.black87,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: ValueListenableBuilder<int>(
            valueListenable: rootPushCount,
            builder: (_, navPushes, _) {
              return ValueListenableBuilder<String>(
                valueListenable: lastRootRouteName,
                builder: (_, lastName, _) {
                  return Text(
                    'router: $_uri  (delegateTicks=$_delegateTicks navPushes=$navPushes last=$lastName)',
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 11),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
