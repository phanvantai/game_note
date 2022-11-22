import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/community/presentation/auth/bloc/auth_bloc.dart';

import '../../../../core/constants/assets_path.dart';
import '../../../../core/constants/constants.dart';
import '../widgets/custom_button.dart';

class AuthButtonsView extends StatelessWidget {
  const AuthButtonsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomButton(
          paddingHorizontal: 32,
          backgroundColor: Colors.cyan,
          onPressed: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                AssetsPath.googleIcon,
                width: 20,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Text(
                'Sign in with Google',
                style: kDefaultBoldWhite,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CustomButton(
          paddingHorizontal: 32,
          backgroundColor: Colors.deepPurpleAccent,
          onPressed: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.apple, size: 20),
              SizedBox(width: 8),
              Text(
                'Sign in with Apple',
                style: kDefaultBoldWhite,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CustomButton(
          paddingHorizontal: 32,
          backgroundColor: Colors.green,
          onPressed: () => context.read<AuthBloc>().add(SignInEmailEvent()),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.email, size: 20),
              SizedBox(width: 8),
              Text(
                'Sign in with email',
                style: kDefaultBoldWhite,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CustomButton(
          paddingHorizontal: 32,
          backgroundColor: Colors.red,
          onPressed: () => context.read<AuthBloc>().add(CreateAccountEvent()),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.edit, size: 20),
              SizedBox(width: 8),
              Text(
                'Create new account',
                style: kDefaultBoldWhite,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
