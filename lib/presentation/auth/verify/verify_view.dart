import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/presentation/common/smart_back.dart';

import '../../../injection_container.dart';

class VerifyView extends StatelessWidget {
  VerifyView({super.key});

  final TextEditingController _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: const SmartBackButton(),
        title: Text(context.l10n.authSignIn, style: textTheme.titleMedium),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: double.maxFinite, height: 64),
            AppCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 48,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.authVerifyAccountTitle,
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.authVerificationSent,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    decoration: appInputDecoration(
                      context: context,
                      labelText: context.l10n.authVerificationCode,
                      prefixIcon: Icons.pin_outlined,
                    ),
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        if (kDebugMode) {
                          print(_codeController.text);
                        }
                        try {
                          final result = await getIt<GNAuth>()
                              .signInWithPhoneNumber(_codeController.text);
                          if (kDebugMode) {
                            print(result);
                          }
                          // ignore: use_build_context_synchronously
                          Navigator.of(context).pop(true);
                        } catch (e) {
                          if (kDebugMode) {
                            print(e);
                          }
                        }
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(context.l10n.authVerify),
                    ),
                  ),
                  // const SizedBox(height: 16),
                  // TextButton(
                  //   onPressed: () {
                  //     // Resend code
                  //   },
                  //   child: const Text('Gửi lại mã xác thực'),
                  // ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
