import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/presentation/esport/groups/groups_view.dart';
import 'package:pes_arena/presentation/home/dashboard/dashboard_view.dart';
import 'package:pes_arena/presentation/notification/bloc/notification_bloc.dart';
import 'package:pes_arena/routing.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trang chủ'),
          centerTitle: false,
          actions: [
            BlocBuilder<NotificationBloc, NotificationState>(
              builder: (context, state) => IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined),
                    if (state.unreadNotificationsCount > 0)
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          width: 8,
                          height: 8,
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  context.push(Routing.notification);
                },
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Bảng điều khiển'),
              Tab(text: 'Nhóm'),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [DashboardView(), GroupsView(embedded: true)],
        ),
      ),
    );
  }
}
