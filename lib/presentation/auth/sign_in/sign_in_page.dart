import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/auth/sign_in/bloc/sign_in_bloc.dart';
import 'package:game_note/presentation/auth/sign_in/sign_in_view.dart';
import 'package:game_note/injection_container.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SignInBloc>(),
      child: const SignInView(),
    );
  }
}
