import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:pes_arena/presentation/home/dashboard/dashboard_view.dart';
import 'package:pes_arena/presentation/home/ongoing_tournaments/bloc/ongoing_tournaments_bloc.dart';
import 'package:pes_arena/presentation/home/widgets/ongoing_tournaments_banner.dart';
import 'package:visibility_detector/visibility_detector.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _visibilityKey = Key('home_page');

  // Tracks whether initState already did the first load, so VisibilityDetector
  // skips the redundant fire on the very first render.
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final ids = context
        .read<GroupBloc>()
        .state
        .userGroups
        .map((g) => g.id)
        .toList();
    context.read<OngoingTournamentsBloc>().add(LoadOngoingTournaments(ids));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return BlocListener<GroupBloc, GroupState>(
      listenWhen: (prev, curr) => prev.userGroups != curr.userGroups,
      listener: (context, state) => _reload(),
      child: VisibilityDetector(
        key: _visibilityKey,
        onVisibilityChanged: (info) {
          if (info.visibleFraction > 0.5 && mounted) {
            if (_initialLoadDone) {
              _reload();
            } else {
              _initialLoadDone = true;
            }
          }
        },
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
        ),
      ),
    );
  }
}
