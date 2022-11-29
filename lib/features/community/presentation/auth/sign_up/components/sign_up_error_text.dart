import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/community/presentation/auth/sign_up/bloc/sign_up_bloc.dart';

class SignUpErrorText extends StatelessWidget {
  const SignUpErrorText({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpBloc, SignUpState>(
      buildWhen: (previous, current) =>
          previous.status != current.status || previous.error != current.error,
      builder: (context, state) => Text(
        state.error,
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}
