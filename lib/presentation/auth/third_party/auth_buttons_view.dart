import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/common/view_status.dart';
import 'package:game_note/core/constants/assets_path.dart';
import 'package:game_note/presentation/auth/third_party/bloc/third_party_bloc.dart';
import 'package:game_note/injection_container.dart';

import '../../../core/constants/constants.dart';
import '../auth_custom_button.dart';

class AuthButtonsView extends StatelessWidget {
  const AuthButtonsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final thirdPartyBloc = getIt<ThirdPartyBloc>();
    return BlocConsumer<ThirdPartyBloc, ThirdPartyState>(
      bloc: thirdPartyBloc,
      listener: (context, state) {
        if (kDebugMode) {
          print('🔄 ThirdPartyBloc state changed: ${state.status}');
          if (state.error.isNotEmpty) {
            print('❌ Error: ${state.error}');
          }
        }

        // Show error message to user
        if (state.status == ViewStatus.failure && state.error.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi đăng nhập: ${state.error}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }

        // Show success message
        if (state.status == ViewStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng nhập thành công!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) => Column(
        children: [
          const SizedBox(height: 16),
          AuthCustomButton(
            paddingHorizontal: 32,
            backgroundColor: Colors.blueGrey,
            onPressed: state.status == ViewStatus.loading
                ? null
                : () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    thirdPartyBloc.add(const ThirdPartySignInGoogle());
                  },
            child: state.status == ViewStatus.loading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Đang đăng nhập...',
                        style: kDefaultBoldWhite,
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        AssetsPath.iconGoogle,
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Đăng nhập với Google',
                        style: kDefaultBoldWhite,
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 16),
          if (Platform.isIOS)
            AuthCustomButton(
              paddingHorizontal: 32,
              backgroundColor: Colors.redAccent,
              onPressed: () {
                thirdPartyBloc.add(const ThirdPartySignInApple());
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AssetsPath.iconApple,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Đăng nhập với Apple',
                    style: kDefaultBoldWhite,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
