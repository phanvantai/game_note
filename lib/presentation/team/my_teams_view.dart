import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/presentation/team/bloc/teams_bloc.dart';

class MyTeamsView extends StatelessWidget {
  const MyTeamsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TeamsBloc, TeamsState>(
      buildWhen: (previous, current) => previous.myTeams != current.myTeams,
      builder: (context, state) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(12),
          color: Colors.pink[50],
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          shape: Border.all(color: Colors.transparent),
          collapsedShape: Border.all(color: Colors.transparent),
          initiallyExpanded: true,
          trailing: ElevatedButton(
            onPressed: () {
              showToast('Sắp ra mắt');
              // Navigator.of(context).pushNamed(Routing.createTeam);
            },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.white,
            ),
            child: const Text('Tạo đội'),
          ),
          title: const Text(
            'Đội của tôi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: _buildMyTeams(state),
        ),
      ),
    );
  }

  List<Widget> _buildMyTeams(TeamsState state) {
    if (state.viewStatus.isLoading) {
      return const [
        Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ];
    }
    if (state.myTeams.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Center(
            child: Text('Bạn chưa tham gia đội nào'),
          ),
        ),
      ];
    } else {
      return state.myTeams
          .map(
            (team) => ListTile(
              title: Text(team.name),
              onTap: () {
                // Navigator.of(context).pushNamed(Routing.teamDetail, arguments: team);
              },
            ),
          )
          .toList();
    }
  }
}
