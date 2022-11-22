import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/community/presentation/auth/bloc/auth_bloc.dart';
import 'package:game_note/features/community/presentation/auth/create_account_view.dart';
import 'package:game_note/features/community/presentation/auth/sign_in_view.dart';

import '../../../../core/constants/assets_path.dart';
import '../../../../features/community/presentation/widgets/custom_button.dart';
import '../../../common/presentation/bloc/app_bloc.dart';
import 'buttons_view.dart';

class AuthView extends StatelessWidget {
  const AuthView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Image.asset(
              AssetsPath.appIcon,
              color: Colors.white,
              width: MediaQuery.of(context).size.width / 3,
            ),
            const SizedBox(height: 48, width: double.maxFinite),
            const Text(
              'Game Note',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            ),
            const SizedBox(height: 48, width: double.maxFinite),
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: _buildWidget(context, state),
              ),
            ),
            const Spacer(),
            const Spacer(),
            const Spacer(),
            Row(
              children: [
                const Spacer(),
                Expanded(
                  child: Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Or', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 4),
            CustomButton(
              backgroundColor: Colors.grey,
              paddingHorizontal: 32,
              buttonText: 'Switch to offline mode',
              onPressed: () => context
                  .read<AppBloc>()
                  .add(const SwitchAppMode(AppStatus.offline)),
            ),
          ],
        ),
      ),
    );
  }

  _buildWidget(BuildContext context, AuthState state) {
    switch (state.status) {
      case AuthStatus.initial:
        return const AuthButtonsView();
      case AuthStatus.createAccount:
        return const CreateAccountView();
      case AuthStatus.signInMail:
        return const SignInView();
      default:
        return const AuthButtonsView();
    }
  }
}
