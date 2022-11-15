import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/features/community/bloc/community_bloc.dart';

import '../../../../core/constants/assets_path.dart';
import '../../../app/bloc/app_bloc.dart';
import '../../../widgets/custom_button.dart';

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
            GestureDetector(
              onDoubleTap: () =>
                  context.read<CommunityBloc>().add(LoginEvent()),
              child: Image.asset(
                AssetsPath.appIcon,
                color: Colors.white,
                width: MediaQuery.of(context).size.width / 3,
              ),
            ),
            const SizedBox(height: 48, width: double.maxFinite),
            const Text(
              'Game Note',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            ),
            const SizedBox(height: 48, width: double.maxFinite),
            CustomButton(
              paddingHorizontal: 32,
              buttonText: 'Sign in with Google',
              backgroundColor: Colors.purpleAccent,
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            CustomButton(
              paddingHorizontal: 32,
              buttonText: 'Sign in with Apple',
              backgroundColor: Colors.indigoAccent,
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            CustomButton(
              paddingHorizontal: 32,
              buttonText: 'Sign in with email',
              backgroundColor: Colors.grey,
              onPressed: () {},
            ),
            const SizedBox(height: 16),
            CustomButton(
              paddingHorizontal: 32,
              buttonText: 'Sign up with email',
              backgroundColor: Colors.red,
              onPressed: () {},
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
              paddingHorizontal: 64,
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
}
