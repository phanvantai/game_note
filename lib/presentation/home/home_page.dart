import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:pes_arena/presentation/esport/tournament/tournament_view.dart';
import 'package:pes_arena/presentation/home/dashboard/dashboard_view.dart';
import 'package:pes_arena/presentation/home/ongoing_tournaments/bloc/ongoing_tournaments_bloc.dart';
import 'package:pes_arena/presentation/home/widgets/ongoing_tournaments_banner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _syncFromGroups(context.read<GroupBloc>().state.userGroups);
  }

  void _syncFromGroups(List<dynamic> groups) {
    final ids = groups.map((g) => g.id as String).toList();
    final bloc = context.read<OngoingTournamentsBloc>();
    if (!_sameIds(bloc.state.loadedGroupIds, ids)) {
      bloc.add(LoadOngoingTournaments(ids));
    }
  }

  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sa = [...a]..sort();
    final sb = [...b]..sort();
    for (var i = 0; i < sa.length; i++) {
      if (sa[i] != sb[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return BlocListener<GroupBloc, GroupState>(
      listenWhen: (prev, curr) => prev.userGroups != curr.userGroups,
      listener: (context, state) => _syncFromGroups(state.userGroups),
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.secondary.withValues(alpha: 0.16),
                theme.scaffoldBackgroundColor,
                colorScheme.primary.withValues(alpha: 0.06),
              ],
              stops: const [0, 0.42, 1],
            ),
          ),
          child: const SafeArea(
            child: Column(
              children: [
                OngoingTournamentsBanner(),
                Expanded(child: DashboardView()),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => openCreateTournament(context),
          label: const Text('Tạo giải đấu'),
          icon: const Icon(Icons.add),
        ),
      ),
    );
  }
}
