import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/injection_container.dart';

import '../../../../../core/constants/constants.dart';
import '../../../../community/presentation/widgets/custom_button.dart';
import '../../../../community/presentation/widgets/custom_text_form_field.dart';
import 'bloc/sign_in_bloc.dart';

class SignInView extends StatelessWidget {
  const SignInView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SignInBloc>(),
      child: BlocListener<SignInBloc, SignInState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == SignInStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                state.error,
                //textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.grey,
            ));
          }
          if (state.status == SignInStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                "Sign in successfully",
                //textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.grey,
            ));
          }
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white54,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              BlocBuilder<SignInBloc, SignInState>(
                builder: (context, state) => CustomTextFormField(
                  placeholder: 'Email',
                  onChanged: (value) =>
                      context.read<SignInBloc>().add(SignInEmailChanged(value)),
                  textInputType: TextInputType.emailAddress,
                ),
              ),
              SizedBox(height: kDefaultPadding),
              BlocBuilder<SignInBloc, SignInState>(
                builder: (context, state) => CustomTextFormField(
                  isSecurity: true,
                  placeholder: 'Password',
                  onChanged: (value) => context
                      .read<SignInBloc>()
                      .add(SignInPasswordChanged(value)),
                  textInputType: TextInputType.text,
                ),
              ),
              SizedBox(height: kDefaultPadding),
              SizedBox(height: kDefaultPadding),
              // Text(
              //   'Forgot password?',
              //   style: TextStyle(decoration: TextDecoration.underline),
              // ),
              SizedBox(height: kDefaultPadding),
              BlocBuilder<SignInBloc, SignInState>(
                builder: (context, state) => CustomButton(
                  paddingHorizontal: 16,
                  onPressed: () =>
                      context.read<SignInBloc>().add(SignInSubmitted()),
                  child: state.status == SignInStatus.loading
                      ? kDefaultLoading
                      : const Text('SIGN IN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
