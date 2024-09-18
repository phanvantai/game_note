import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
          print(state);
        }
      },
      builder: (context, state) => Column(
        children: [
          const SizedBox(height: 16),
          AuthCustomButton(
            paddingHorizontal: 32,
            backgroundColor: Colors.blueGrey,
            onPressed: () {
              thirdPartyBloc.add(const ThirdPartySignInGoogle());
            },
            child: Row(
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
          // if (Platform.isIOS)
          //   AuthCustomButton(
          //     paddingHorizontal: 32,
          //     backgroundColor: Colors.redAccent,
          //     onPressed: () {
          //       thirdPartyBloc.add(const ThirdPartySignInApple());
          //     },
          //     child: Row(
          //       mainAxisAlignment: MainAxisAlignment.center,
          //       children: [
          //         Image.asset(
          //           AssetsPath.iconApple,
          //           width: 24,
          //           height: 24,
          //         ),
          //         const SizedBox(width: 8),
          //         const Text(
          //           'Đăng nhập với Apple',
          //           style: kDefaultBoldWhite,
          //         ),
          //       ],
          //     ),
          //   ),
        ],
      ),
    );
  }
}
