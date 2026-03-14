import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/constants/assets_path.dart';
import 'package:pes_arena/core/theme/app_colors.dart';
import 'package:pes_arena/presentation/auth/third_party/bloc/third_party_bloc.dart';
import 'package:pes_arena/injection_container.dart';

class AuthButtonsView extends StatelessWidget {
  const AuthButtonsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final thirdPartyBloc = getIt<ThirdPartyBloc>();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocConsumer<ThirdPartyBloc, ThirdPartyState>(
      bloc: thirdPartyBloc,
      listener: (context, state) {
        if (kDebugMode) {
          print('ThirdPartyBloc state changed: ${state.status}');
          if (state.error.isNotEmpty) {
            print('Error: ${state.error}');
          }
        }

        if (state.status == ViewStatus.failure && state.error.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: colorScheme.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 4),
            ),
          );
        }

        if (state.status == ViewStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Đăng nhập thành công!'),
              backgroundColor: AppColors.success(context),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.status == ViewStatus.loading;

        return Column(
          children: [
            // Google sign-in button
            SizedBox(
              height: 48,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        FocusManager.instance.primaryFocus?.unfocus();
                        thirdPartyBloc.add(const ThirdPartySignInGoogle());
                      },
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDark
                      ? colorScheme.surfaceContainerHighest
                      : Colors.white,
                  side: BorderSide(
                    color: colorScheme.outline,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onSurface,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            AssetsPath.iconGoogle,
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Tiếp tục với Google',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (Platform.isIOS) ...[
              const SizedBox(height: 12),
              // Apple sign-in button
              SizedBox(
                height: 48,
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          thirdPartyBloc.add(const ThirdPartySignInApple());
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : Colors.black,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        AssetsPath.iconApple,
                        width: 20,
                        height: 20,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Tiếp tục với Apple',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
