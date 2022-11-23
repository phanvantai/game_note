import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/sign_in_bloc.dart';

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
          debugPrint(value);
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
