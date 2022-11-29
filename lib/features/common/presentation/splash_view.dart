import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/constants/assets_path.dart';
import 'package:game_note/core/helpers/app_helper.dart';

import 'bloc/app_bloc.dart';

class SplashView extends StatelessWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(milliseconds: 600))
        .then((value) => context.read<AppBloc>().add(SwitchAppMode(appStatus)));
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Image.asset(
            AssetsPath.appIcon,
            color: Colors.white,
            width: MediaQuery.of(context).size.width / 3,
          ),
        ),
      ),
    );
  }
}
