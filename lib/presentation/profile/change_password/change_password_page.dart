import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/injection_container.dart';
import 'package:game_note/presentation/profile/change_password/bloc/change_password_bloc.dart';
import 'package:game_note/presentation/profile/change_password/change_password_view.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChangePasswordBloc>(),
      child: const ChangePasswordView(),
    );
  }
}
