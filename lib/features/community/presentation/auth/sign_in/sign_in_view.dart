import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/community/presentation/auth/sign_in/bloc/sign_in_bloc.dart';
import 'package:game_note/features/community/presentation/widgets/custom_button.dart';

import '../../../../../core/constants/constants.dart';
import '../../widgets/custom_text_form_field.dart';
import '../bloc/auth_bloc.dart';

class SignInView extends StatelessWidget {
  const SignInView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignInBloc(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          children: [
            const SignInEmail(),
            const SizedBox(height: kDefaultPadding),
            const CustomTextFormField(
              placeholder: 'Password',
              isSecurity: true,
            ),
            const SizedBox(height: kDefaultPadding),
            const SizedBox(height: kDefaultPadding),
            const Text(
              'Forgot password?',
              style: TextStyle(decoration: TextDecoration.underline),
            ),
            const SizedBox(height: kDefaultPadding),
            CustomButton(
              paddingHorizontal: 16,
              onPressed: () {},
              buttonText: 'SIGN IN',
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                context.read<AuthBloc>().add(InitialEvent());
              },
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

class SignInEmail extends StatelessWidget {
  const SignInEmail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignInBloc, SignInState>(
      builder: (context, state) => TextFormField(
        cursorColor: Colors.white,
        autocorrect: false,
        onChanged: (value) {
          context.read<SignInBloc>().add(SignInEmailChanged(value));
        },
        validator: (value) {
          print(value);
          return null;
        },
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(
          hintText: 'Email',
        ),
      ),
    );
  }
}
