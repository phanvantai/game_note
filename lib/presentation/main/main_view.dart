import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/l10n/l10n.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';

import '../esport/groups/groups_view.dart';
import '../esport/tournament/tournament_view.dart';
import '../home/dashboard/bloc/dashboard_bloc.dart';
import '../home/home_page.dart';
import '../profile/profile_view.dart';

class MainView extends StatefulWidget {
  final int initialTabIndex;

  const MainView({super.key, this.initialTabIndex = 0});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> with TickerProviderStateMixin {
  late final List<_TabSpec> _tabs;

  late TabController _tabController;
  @override
  void initState() {
    super.initState();

    _tabs = const [
      _TabSpec(
        icon: Icons.sports_esports_outlined,
        activeIcon: Icons.sports_esports,
        tab: _MainTab.arena,
        page: HomePage(),
      ),
      _TabSpec(
        icon: Icons.group_outlined,
        activeIcon: Icons.group,
        tab: _MainTab.groups,
        page: GroupsView(),
      ),
      _TabSpec(
        icon: Icons.emoji_events_outlined,
        activeIcon: Icons.emoji_events,
        tab: _MainTab.tournaments,
        page: TournamentView(),
      ),
      _TabSpec(
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        tab: _MainTab.profile,
        page: ProfileView(),
      ),
    ];

    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, _tabs.length - 1).toInt(),
    );

    context.read<GroupBloc>().add(GetEsportGroups());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TabBarView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _tabController,
        children: _tabs.map((t) => t.page).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabController.index,
        onDestinationSelected: _onItemTapped,
        destinations: _tabs
            .map(
              (t) => NavigationDestination(
                icon: _TabIcon(icon: t.icon),
                selectedIcon: _TabIcon(icon: t.activeIcon),
                label: _labelFor(context, t.tab),
              ),
            )
            .toList(),
      ),
    );
  }

  void _onItemTapped(int index) {
    // The dashboard summary is cheap to compute server-side, so coming back
    // to Arena reloads it instead of showing the stats from app start.
    if (_tabs[index].tab == _MainTab.arena && _tabController.index != index) {
      context.read<DashboardBloc>().add(RefreshDashboard());
    }
    setState(() {
      _tabController.index = index;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _labelFor(BuildContext context, _MainTab tab) {
    final l10n = context.l10n;
    return switch (tab) {
      _MainTab.arena => l10n.mainTabArena,
      _MainTab.groups => l10n.mainTabGroups,
      _MainTab.tournaments => l10n.mainTabTournaments,
      _MainTab.profile => l10n.mainTabProfile,
    };
  }
}

enum _MainTab { arena, groups, tournaments, profile }

class _TabSpec {
  final IconData icon;
  final IconData activeIcon;
  final _MainTab tab;
  final Widget page;

  const _TabSpec({
    required this.icon,
    required this.activeIcon,
    required this.tab,
    required this.page,
  });
}

class _TabIcon extends StatelessWidget {
  final IconData icon;

  const _TabIcon({required this.icon});

  @override
  Widget build(BuildContext context) => Icon(icon);
}
