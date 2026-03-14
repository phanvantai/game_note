import 'package:flutter/material.dart';
import 'package:pes_arena/core/constants/assets_path.dart';
import 'package:pes_arena/presentation/app/offline_button.dart';

import 'sign_in/sign_in_page.dart';
import 'third_party/auth_buttons_view.dart';

class AuthView extends StatelessWidget {
  const AuthView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: const [OfflineButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // App logo
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  AssetsPath.appIcon,
                  width: 80,
                  height: 80,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PES Arena',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Đăng nhập để tiếp tục',
                style: TextStyle(
                  fontSize: 15,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 40),
              // Email sign-in form
              const SignInPage(),
              const SizedBox(height: 32),
              // Divider
              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: colorScheme.outline,
                      thickness: 0.5,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Hoặc',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: colorScheme.outline,
                      thickness: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Third-party sign-in buttons
              const AuthButtonsView(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
