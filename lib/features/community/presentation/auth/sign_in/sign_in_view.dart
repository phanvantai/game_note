import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/features/community/presentation/auth/bloc/auth_bloc.dart';
import 'package:game_note/features/community/presentation/auth/custom_back_button.dart';
import 'package:game_note/features/community/presentation/bloc/community_bloc.dart';

import '../../../../../core/constants/constants.dart';
import '../../../../../injection_container.dart';
import 'bloc/sign_in_bloc.dart';
import 'components/sign_in_button.dart';
import 'components/sign_in_email.dart';
import 'components/sign_in_password.dart';

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
            //
            context.read<CommunityBloc>().add(LoginEvent(state.userModel!));
            context.read<AuthBloc>().add(AuthInitialEvent());
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: const [
              SignInEmail(),
              SizedBox(height: kDefaultPadding),
              SignInPassword(),
              SizedBox(height: kDefaultPadding),
              SizedBox(height: kDefaultPadding),
              // Text(
              //   'Forgot password?',
              //   style: TextStyle(decoration: TextDecoration.underline),
              // ),
              SizedBox(height: kDefaultPadding),
              SignInButton(),
              SizedBox(height: 16),
              CustomBackButton(),
            ],
          ),
        ),
      ),
    );
  }
}
