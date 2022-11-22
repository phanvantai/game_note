import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/constants/constants.dart';
import 'package:game_note/features/community/presentation/auth/bloc/auth_bloc.dart';
import 'package:game_note/features/community/presentation/widgets/custom_button.dart';

import '../widgets/custom_text_form_field.dart';

class CreateAccountView extends StatelessWidget {
  const CreateAccountView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const CustomTextFormField(
            placeholder: 'Email',
          ),
          const SizedBox(height: kDefaultPadding),
          const CustomTextFormField(
            placeholder: 'Password',
          ),
          const SizedBox(height: kDefaultPadding),
          const CustomTextFormField(
            placeholder: 'Confirm Password',
          ),
          const SizedBox(height: kDefaultPadding),
          CustomButton(
            paddingHorizontal: kDefaultPadding,
            onPressed: () {},
            buttonText: "SIGN UP",
          ),
          const SizedBox(height: 12),
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
    );
  }
}
