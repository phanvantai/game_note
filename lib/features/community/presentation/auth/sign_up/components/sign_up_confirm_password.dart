import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/community/presentation/auth/sign_up/bloc/sign_up_bloc.dart';

import '../../../widgets/custom_text_form_field.dart';

class SignUpConfirmPassword extends StatelessWidget {
  const SignUpConfirmPassword({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpBloc, SignUpState>(
      builder: (context, state) => CustomTextFormField(
        isSecurity: true,
        placeholder: 'Confirm Password',
        onChanged: (value) =>
            context.read<SignUpBloc>().add(SignUpConfirmPasswordChanged(value)),
      ),
    );
  }
}
