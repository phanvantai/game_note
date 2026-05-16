import 'package:flutter/material.dart';
import 'package:pes_arena/core/constants/assets_path.dart';

/// Held route while Firebase Auth restores the session. The router's
/// redirect callback bounces every request here until [AppStatus] leaves
/// `initializing`, then re-evaluates and forwards to the original target
/// (preserved in the `next` query param).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                AssetsPath.appIcon,
                width: 72,
                height: 72,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
