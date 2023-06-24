import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/constants/constants.dart';
import 'package:game_note/features/community/presentation/auth/custom_back_button.dart';
import 'package:game_note/features/community/presentation/auth/sign_up/bloc/sign_up_bloc.dart';
import 'package:game_note/features/community/presentation/auth/sign_up/components/sign_up_button.dart';
import 'package:game_note/features/community/presentation/auth/sign_up/components/sign_up_confirm_password.dart';
import 'package:game_note/features/community/presentation/auth/sign_up/components/sign_up_email.dart';
import 'package:game_note/features/community/presentation/auth/sign_up/components/sign_up_error_text.dart';
import 'package:game_note/features/community/presentation/auth/sign_up/components/sign_up_password.dart';

import '../../../../../injection_container.dart';
import '../../bloc/community_bloc.dart';
import '../bloc/auth_bloc.dart';

class SignUpView extends StatelessWidget {
  const SignUpView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SignUpBloc>(),
      child: BlocListener<SignUpBloc, SignUpState>(
        listener: (context, state) {
          if (state.status == SignUpStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                "Sign up successfully",
                //textAlign: TextAlign.center,
              ),
              backgroundColor: Colors.grey,
            ));
            //
            context.read<CommunityBloc>().add(LoginEvent(state.userModel!));
            context.read<AuthBloc>().add(AuthInitialEvent());
          }
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              SignUpEmail(),
              SizedBox(height: kDefaultPadding),
              SignUpPassword(),
              SizedBox(height: kDefaultPadding),
              SignUpConfirmPassword(),
              SizedBox(height: kDefaultPadding),
              SignUpErrorText(),
              SizedBox(height: kDefaultPadding),
              SignUpButton(),
              SizedBox(height: 12),
              CustomBackButton(),
            ],
          ),
        ),
      ),
    );
  }
}
