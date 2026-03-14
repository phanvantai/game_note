import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';
import 'package:pes_arena/presentation/team/bloc/teams_bloc.dart';

class MyTeamsView extends StatelessWidget {
  const MyTeamsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<TeamsBloc, TeamsState>(
      buildWhen: (previous, current) => previous.myTeams != current.myTeams,
      builder: (context, state) => AppCard(
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: Border.all(color: Colors.transparent),
          collapsedShape: Border.all(color: Colors.transparent),
          initiallyExpanded: true,
          trailing: FilledButton.tonal(
            onPressed: () {
              showToast('Sắp ra mắt');
              // Navigator.of(context).pushNamed(Routing.createTeam);
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
            ),
            child: const Text('Tạo đội'),
          ),
          title: Text(
            'Đội của tôi',
            style: textTheme.titleSmall,
          ),
          children: _buildMyTeams(state, context),
        ),
      ),
    );
  }

  List<Widget> _buildMyTeams(TeamsState state, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (state.viewStatus.isLoading) {
      return [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: CircularProgressIndicator(
              color: colorScheme.secondary,
            ),
          ),
        ),
      ];
    }
    if (state.myTeams.isEmpty) {
      return const [
        AppEmptyState(
          icon: Icons.groups_outlined,
          title: 'Bạn chưa tham gia đội nào',
        ),
      ];
    } else {
      return state.myTeams
          .map(
            (team) => ListTile(
              leading: Icon(
                Icons.groups_outlined,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              title: Text(
                team.name,
                style: textTheme.bodyMedium,
              ),
              trailing: Icon(
                Icons.chevron_right_outlined,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
              onTap: () {
                // Navigator.of(context).pushNamed(Routing.teamDetail, arguments: team);
              },
            ),
          )
          .toList();
    }
  }
}
