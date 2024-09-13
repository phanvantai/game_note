import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/esport/bloc/esport_bloc.dart';
import 'package:game_note/presentation/esport/tournament/bloc/tournament_bloc.dart';
import 'package:provider/provider.dart';

import '../../injection_container.dart';
import '../esport/groups/bloc/group_bloc.dart';
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
        BlocProvider(create: (_) => getIt<EsportBloc>()..add(InitEsport())),
        BlocProvider(
          create: (_) => getIt<GroupBloc>(),
        ),
        BlocProvider(
          create: (_) => getIt<TournamentBloc>()..add(GetTournaments()),
        ),
      ],
      child: const MainView(),
    );
  }
}
