import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'firebase/firestore/esport/group/gn_esport_group.dart';
import 'firebase/firestore/user/gn_user.dart';
import 'offline/presentation/offline_view.dart';
import 'presentation/app/app_view.dart';
import 'presentation/auth/verify/verify_page.dart';
import 'presentation/esport/groups/group_detail/group_detail_page.dart';
import 'presentation/home/dashboard/detail/dashboard_detail_page.dart';
import 'presentation/esport/tournament/tournament_detail/tournament_detail_page.dart';
import 'presentation/notification/notification_page.dart';
import 'presentation/profile/change_password/change_password_page.dart';
import 'presentation/profile/feedback/feedback_view.dart';
import 'presentation/profile/setting/setting_page.dart';
import 'presentation/profile/update/update_profile_page.dart';
import 'presentation/sync/sync_page.dart';

class Routing {
  static const String app = '/';
  static const String offline = '/offline';
  static const String offlineLeague = '/offline/league';
  static const String league = '/league';
  static const String verify = '/verify';

  // community
  static const String createTeam = '/create-team';

  // group / league — base paths, use helper methods for navigation
  static const String groupDetail = '/group';
  static const String tournamentDetail = '/tournament';

  static String groupDetailPath(String groupId) => '/group/$groupId';
  static String tournamentDetailPath(String leagueId) =>
      '/tournament/$leagueId';

  // profile
  static const String updateProfile = '/update-profile';
  static const String setting = '/setting';
  static const String changePassword = '/change-password';
  static const String feedback = '/feedback';

  // dashboard
  static const String dashboardDetail = '/dashboard';

  // notification
  static const String notification = '/notification';

  // sync offline → online
  static const String syncOfflineData = '/sync-offline-data';
}

CustomTransitionPage<T> _slide<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
  int duration = 200,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: Duration(milliseconds: kIsWeb ? 120 : duration),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (kIsWeb) {
        return FadeTransition(opacity: animation, child: child);
      }
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      return SlideTransition(
        position: animation.drive(Tween(begin: begin, end: end)),
        child: child,
      );
    },
  );
}

class _NotFoundPage extends StatelessWidget {
  const _NotFoundPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Không tìm thấy trang'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => GoRouter.of(context).go(Routing.app),
              child: const Text('Về trang chủ'),
            ),
          ],
        ),
      ),
    );
  }
}

final GoRouter appRouter = GoRouter(
  initialLocation: Routing.app,
  redirect: _appRedirect,
  errorBuilder: (context, state) => const _NotFoundPage(),
  routes: _appRoutes,
);

String? _appRedirect(BuildContext context, GoRouterState state) {
  if (kIsWeb) {
    final loc = state.matchedLocation;
    if (loc == Routing.offline ||
        loc == Routing.offlineLeague ||
        loc == Routing.syncOfflineData) {
      return Routing.app;
    }
  }
  return null;
}

final List<RouteBase> _appRoutes = [
  GoRoute(
    path: Routing.app,
    pageBuilder: (context, state) =>
        _slide(context: context, state: state, child: const AppView()),
  ),
  GoRoute(
    path: Routing.offline,
    pageBuilder: (context, state) =>
        _slide(context: context, state: state, child: const OfflineView()),
    routes: [
      GoRoute(
        path: 'league',
        pageBuilder: (context, state) =>
            _slide(context: context, state: state, child: const OfflineView()),
      ),
    ],
  ),
  GoRoute(
    path: Routing.verify,
    pageBuilder: (context, state) =>
        _slide(context: context, state: state, child: const VerifyPage()),
  ),
  GoRoute(
    path: '/group/:groupId',
    pageBuilder: (context, state) => _slide(
      context: context,
      state: state,
      child: GroupDetailPage(
        groupId: state.pathParameters['groupId']!,
        initialGroup: state.extra as GNEsportGroup?,
      ),
    ),
  ),
  GoRoute(
    path: '/tournament/:leagueId',
    pageBuilder: (context, state) => _slide(
      context: context,
      state: state,
      child: TournamentDetailPage(leagueId: state.pathParameters['leagueId']!),
    ),
  ),
  GoRoute(
    path: Routing.updateProfile,
    pageBuilder: (context, state) => _slide(
      context: context,
      state: state,
      child: UpdateProfilePage(user: state.extra as GNUser?),
    ),
  ),
  GoRoute(
    path: Routing.setting,
    pageBuilder: (context, state) =>
        _slide(context: context, state: state, child: const SettingPage()),
  ),
  GoRoute(
    path: Routing.changePassword,
    pageBuilder: (context, state) => _slide(
      context: context,
      state: state,
      child: const ChangePasswordPage(),
    ),
  ),
  GoRoute(
    path: Routing.dashboardDetail,
    pageBuilder: (context, state) => _slide(
      context: context,
      state: state,
      child: const DashboardDetailPage(),
    ),
  ),
  GoRoute(
    path: Routing.notification,
    pageBuilder: (context, state) =>
        _slide(context: context, state: state, child: const NotificationPage()),
  ),
  GoRoute(
    path: Routing.feedback,
    pageBuilder: (context, state) =>
        _slide(context: context, state: state, child: const FeedbackView()),
  ),
  GoRoute(
    path: Routing.syncOfflineData,
    pageBuilder: (context, state) =>
        _slide(context: context, state: state, child: const SyncPage()),
  ),
];
