import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/core/constants/assets_path.dart';
import 'package:game_note/core/helpers/app_helper.dart';
import 'package:game_note/presentation/app/bloc/app_bloc.dart';

import '../../routing.dart';

class SplashView extends StatefulWidget {
  const SplashView({Key? key}) : super(key: key);

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  @override
  void initState() {
    super.initState();

    initAppState();
  }

  initAppState() async {
    await Future.delayed(const Duration(milliseconds: 500));

    context.read<AppBloc>().add(SwitchAppMode(appStatus));
    Navigator.of(context).pushNamed(Routing.app);
  }

  @override
  Widget build(BuildContext context) {
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
