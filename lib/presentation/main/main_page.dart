import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/community/teams/bloc/teams_bloc.dart';
import 'package:game_note/presentation/main/main_view.dart';
import 'package:provider/provider.dart';

import '../../injection_container.dart';

class MainPage extends StatelessWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider(create: (_) => getIt<TeamsBloc>()),
      ],
      child: const MainView(),
    );
  }
}
