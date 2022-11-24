import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/sign_in_bloc.dart';

class SignInPassword extends StatelessWidget {
  const SignInPassword({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignInBloc, SignInState>(
      builder: (context, state) => TextFormField(
        cursorColor: Colors.white,
        autocorrect: false,
        onChanged: (value) {
          context.read<SignInBloc>().add(SignInPasswordChanged(value));
        },
        validator: (value) {
          debugPrint(value);
          return null;
        },
        keyboardType: TextInputType.text,
        decoration: const InputDecoration(
          hintText: 'Password',
        ),
        obscureText: false,
      ),
    );
  }
}
