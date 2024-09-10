import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:game_note/presentation/team/other_teams_view.dart';

import 'bloc/teams_bloc.dart';
import 'my_teams_view.dart';

class TeamsView extends StatefulWidget {
  const TeamsView({Key? key}) : super(key: key);

  @override
  State<TeamsView> createState() => _TeamsViewState();
}

class _TeamsViewState extends State<TeamsView>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();

    context.read<TeamsBloc>().add(GetMyTeams());
    context.read<TeamsBloc>().add(GetOtherTeams());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return const Scaffold(
      body: SafeArea(
          child: Column(
        children: [
          MyTeamsView(),
          SizedBox(height: 16),
          Expanded(child: OtherTeamsView()),
        ],
      )),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
