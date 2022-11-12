import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/features/community/bloc/community_bloc.dart';

import '../../../core/constants/assets_path.dart';
import '../../widgets/custom_button.dart';

class LoginView extends StatelessWidget {
  const LoginView({Key? key}) : super(key: key);

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
            const Spacer(),
            const Spacer(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
