import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/community/presentation/auth/sign_up/bloc/sign_up_bloc.dart';

import '../../../../../../core/constants/constants.dart';
import '../../../widgets/custom_button.dart';

class SignUpButton extends StatelessWidget {
  const SignUpButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SignUpBloc, SignUpState>(
      builder: (context, state) => CustomButton(
        paddingHorizontal: kDefaultPadding,
        onPressed: () =>
            context.read<SignUpBloc>().add(const SignUpSubmitted()),
        child: state.status == SignUpStatus.loading
            ? kDefaultLoading
            : const Text("SIGN UP"),
      ),
    );
  }
}
