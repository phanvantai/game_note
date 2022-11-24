import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/constants/constants.dart';

import '../../../widgets/custom_button.dart';
import '../bloc/sign_in_bloc.dart';

class SignInButton extends StatelessWidget {
  const SignInButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignInBloc, SignInState>(
      builder: (context, state) => CustomButton(
        paddingHorizontal: 16,
        onPressed: () => context.read<SignInBloc>().add(SignInSubmitted()),
        child: state.status == SignInStatus.loading
            ? kDefaultLoading
            : const Text('SIGN IN'),
      ),
    );
  }
}
