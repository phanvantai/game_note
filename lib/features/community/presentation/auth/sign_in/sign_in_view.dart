import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/constants/constants.dart';
import '../../../../../injection_container.dart';
import '../bloc/auth_bloc.dart';
import 'bloc/sign_in_bloc.dart';
import 'components/sign_in_button.dart';
import 'components/sign_in_email.dart';
import 'components/sign_in_password.dart';

class SignInView extends StatelessWidget {
  const SignInView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SignInBloc>(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SignInEmail(),
            const SizedBox(height: kDefaultPadding),
            const SignInPassword(),
            const SizedBox(height: kDefaultPadding),
            const SizedBox(height: kDefaultPadding),
            const Text(
              'Forgot password?',
              style: TextStyle(decoration: TextDecoration.underline),
            ),
            const SizedBox(height: kDefaultPadding),
            const SignInButton(),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.read<AuthBloc>().add(InitialEvent()),
              child: const Text(
                'Back',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
