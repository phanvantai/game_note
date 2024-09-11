import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../../injection_container.dart';
import '../profile/bloc/profile_bloc.dart';
import '../team/bloc/teams_bloc.dart';
import 'main_view.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(create: (_) => getIt<TeamsBloc>()),
        BlocProvider(create: (_) => getIt<ProfileBloc>()),
      ],
      child: const MainView(),
    );
  }
}
