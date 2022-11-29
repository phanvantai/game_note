import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/community/presentation/widgets/custom_text_form_field.dart';

import '../bloc/sign_in_bloc.dart';

class SignInEmail extends StatelessWidget {
  const SignInEmail({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignInBloc, SignInState>(
      builder: (context, state) => CustomTextFormField(
        placeholder: 'Email',
        onChanged: (value) =>
            context.read<SignInBloc>().add(SignInEmailChanged(value)),
        textInputType: TextInputType.emailAddress,
      ),
    );
  }
}
