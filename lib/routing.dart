import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'firebase/firestore/esport/group/gn_esport_group.dart';
import 'firebase/firestore/user/gn_user.dart';
import 'injection_container.dart';
import 'core/localization/locale_notifier.dart';
import 'l10n/l10n.dart';
import 'offline/presentation/offline_view.dart';
import 'presentation/app/app_view.dart';
import 'presentation/app/bloc/app_bloc.dart';
import 'presentation/app/language_selection_page.dart';
import 'presentation/app/splash_page.dart';
import 'presentation/auth/auth_view.dart';
import 'presentation/auth/complete_profile/complete_profile_page.dart';
import 'presentation/esport/groups/group_detail/add_member_page.dart';
import 'presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
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
  static const String splash = '/splash';
  static const String language = '/language';
  static const String login = '/login';
  static const String completeProfile = '/complete-profile';
  static const String offline = '/offline';
  static const String groups = '/groups';
  static const String offlineLeague = '/offline/league';
  static const String league = '/league';

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

  static String safeNextLocation(String? next) => _safeNextLocation(next);
}

// coverage:ignore-start
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
// coverage:ignore-end

// coverage:ignore-start
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
            Text(context.l10n.pageNotFound),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => GoRouter.of(context).go(Routing.app),
              child: Text(context.l10n.backHome),
            ),
          ],
        ),
      ),
    );
  }
}
// coverage:ignore-end

GoRouter createAppRouter({String initialLocation = Routing.app}) {
  return GoRouter(
    initialLocation: initialLocation,
    redirect: _appRedirect,
    refreshListenable: _AppBlocListenable(getIt<AppBloc>()),
    // coverage:ignore-start
    errorBuilder: (context, state) => const _NotFoundPage(),
    // coverage:ignore-end
    routes: _appRoutes, // coverage:ignore-line
  );
}

// coverage:ignore-start
final GoRouter appRouter = createAppRouter();
// coverage:ignore-end

// Paths that anyone can visit without auth. /login is the obvious one;
// /splash is the holding screen while Firebase Auth restores the session.
const _publicPaths = <String>{
  Routing.language,
  Routing.login,
  Routing.splash,
  Routing.completeProfile,
};
int _redirectCount = 0;

void _logRouteFlow(String message) {
  if (kDebugMode) {
    debugPrint('[RouteFlow] $message');
  }
}

String? _redirectResult(int seq, String reason, String? target) {
  _logRouteFlow('#$seq result=$reason -> ${target ?? 'allow'}');
  return target;
}

String _safeNextLocation(String? next) {
  if (next == null || next.isEmpty) return Routing.app;

  final uri = Uri.tryParse(next);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return Routing.app;

  final path = uri.path.isEmpty ? Routing.app : uri.path;
  if (_isKnownRoutePath(path)) return uri.toString();
  return Routing.app;
}

bool _isKnownRoutePath(String path) {
  if (_publicPaths.contains(path)) return true;

  const fixedPaths = <String>{
    Routing.app,
    Routing.offline,
    Routing.offlineLeague,
    Routing.groups,
    Routing.updateProfile,
    Routing.setting,
    Routing.changePassword,
    Routing.dashboardDetail,
    Routing.notification,
    Routing.feedback,
    Routing.syncOfflineData,
  };
  if (fixedPaths.contains(path)) return true;

  final segments = Uri(path: path).pathSegments;
  if (segments.length == 2 &&
      segments.first == 'group' &&
      segments.last.isNotEmpty) {
    return true;
  }
  if (segments.length == 2 &&
      segments.first == 'tournament' &&
      segments.last.isNotEmpty) {
    return true;
  }
  return false;
}

String? _appRedirect(BuildContext context, GoRouterState state) {
  final seq = ++_redirectCount;
  final location = state.matchedLocation;
  final fullUri = state.uri.toString();
  final appStatus = getIt<AppBloc>().state.status;
  final localeNotifier = getIt.isRegistered<LocaleNotifier>()
      ? getIt<LocaleNotifier>()
      : null;

  _logRouteFlow(
    '#$seq enter uri=$fullUri matched=$location '
    'status=$appStatus '
    'hasLocale=${localeNotifier?.hasSavedLocale} '
    'locale=${localeNotifier?.currentLocale?.languageCode}',
  );

  if (localeNotifier != null) {
    if (!localeNotifier.hasSavedLocale && location == Routing.language) {
      return _redirectResult(seq, 'missing-locale-language', null);
    }
    if (!localeNotifier.hasSavedLocale) {
      final target = Uri(
        path: Routing.language,
        queryParameters: {'next': _safeNextLocation(fullUri)},
      ).toString();
      return _redirectResult(seq, 'missing-locale', target);
    }
  }

  // coverage:ignore-start
  if (kIsWeb) {
    if (location == Routing.offline ||
        location == Routing.offlineLeague ||
        location == Routing.syncOfflineData) {
      return _redirectResult(seq, 'web-blocked-route', Routing.app);
    }
  }
  // coverage:ignore-end

  // Auth not yet known — park every protected route on /splash with the
  // intended URL preserved, so the bounceback after auth resolves can land
  // the user exactly where they wanted to go.
  if (appStatus == AppStatus.initializing) {
    if (location == Routing.splash || location == Routing.language) {
      return _redirectResult(seq, 'initializing-public', null);
    }
    final target = Uri(
      path: Routing.splash,
      queryParameters: {'next': fullUri},
    ).toString();
    return _redirectResult(seq, 'initializing-protected', target);
  }

  // coverage:ignore-start
  // Definitely signed out. /login is the destination; if we're already
  // there, stay. If we're on /splash (auth just resolved as "no user"),
  // forward its `next` to /login so the post-login bounce still lands on
  // the originally-requested URL. Anything else: send to /login carrying
  // the current URL as `next`.
  if (appStatus == AppStatus.unauthenticated) {
    if (location == Routing.language) {
      return _redirectResult(seq, 'unauth-language', null);
    }
    if (location == Routing.login) {
      return _redirectResult(seq, 'unauth-login', null);
    }
    final origNext = location == Routing.splash
        ? state.uri.queryParameters['next']
        : fullUri;
    final safeNext = _safeNextLocation(origNext);
    if (safeNext == Routing.app) {
      return _redirectResult(seq, 'unauth-login-no-next', Routing.login);
    }
    final target = Uri(
      path: Routing.login,
      queryParameters: {'next': safeNext},
    ).toString();
    return _redirectResult(seq, 'unauth-protected', target);
  }

  if (appStatus == AppStatus.profileIncomplete) {
    if (location == Routing.language) {
      return _redirectResult(seq, 'profile-incomplete-language', null);
    }
    if (location == Routing.completeProfile) {
      return _redirectResult(seq, 'profile-incomplete-page', null);
    }
    final origNext = location == Routing.splash || location == Routing.login
        ? state.uri.queryParameters['next']
        : fullUri;
    final safeNext = _safeNextLocation(origNext);
    if (safeNext == Routing.app) {
      return _redirectResult(
        seq,
        'profile-incomplete-no-next',
        Routing.completeProfile,
      );
    }
    final target = Uri(
      path: Routing.completeProfile,
      queryParameters: {'next': safeNext},
    ).toString();
    return _redirectResult(seq, 'profile-incomplete-protected', target);
  }

  // Signed in. If we're sitting on /login or /splash, bounce to whatever
  // the user originally asked for; otherwise let them through.
  if (_publicPaths.contains(location)) {
    final safeNext = _safeNextLocation(state.uri.queryParameters['next']);
    if (!_publicPaths.contains(Uri.parse(safeNext).path)) {
      return _redirectResult(seq, 'auth-public-next', safeNext);
    }
    return _redirectResult(seq, 'auth-public-home', Routing.app);
  }
  return _redirectResult(seq, 'auth-protected', null);
  // coverage:ignore-end
}

/// Adapts the AppBloc auth-state stream into a [ChangeNotifier] so
/// `GoRouter.refreshListenable` re-evaluates `_appRedirect` whenever auth
/// transitions (login, logout, initial restore). Without this the router
/// would stay stuck on /splash because redirect only runs on navigation.
// coverage:ignore-start
class _AppBlocListenable extends ChangeNotifier {
  _AppBlocListenable(this._bloc) {
    _last = _bloc.state.status;
    _logRouteFlow('AppBlocListenable.init status=$_last');
    _sub = _bloc.stream.listen((state) {
      if (state.status != _last) {
        _logRouteFlow('AppBlocListenable.notify $_last -> ${state.status}');
        _last = state.status;
        notifyListeners();
      }
    });
  }

  final AppBloc _bloc;
  late AppStatus _last;
  late final StreamSubscription _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
// coverage:ignore-end

// coverage:ignore-start
final List<RouteBase> _appRoutes = [
  GoRoute(
    path: Routing.language,
    pageBuilder: (context, state) => _slide(
      context: context,
      state: state,
      child: LanguageSelectionPage(
        nextLocation: state.uri.queryParameters['next'],
      ),
    ),
  ),
  GoRoute(
    path: Routing.splash,
    pageBuilder: (context, state) =>
        _slide(context: context, state: state, child: const SplashPage()),
  ),
  GoRoute(
    path: Routing.login,
    pageBuilder: (context, state) =>
        _slide(context: context, state: state, child: const AuthView()),
  ),
  GoRoute(
    path: Routing.completeProfile,
    pageBuilder: (context, state) => _slide(
      context: context,
      state: state,
      child: CompleteProfilePage(
        nextLocation: state.uri.queryParameters['next'],
      ),
    ),
  ),
  GoRoute(
    path: Routing.app,
    pageBuilder: (context, state) =>
        _slide(context: context, state: state, child: const AppView()),
  ),
  GoRoute(
    path: Routing.groups,
    pageBuilder: (context, state) => _slide(
      context: context,
      state: state,
      child: const AppView(initialTabIndex: 1),
    ),
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
    path: '/group/:groupId/add-member',
    pageBuilder: (context, state) {
      final extra = state.extra as Map<String, dynamic>;
      return _slide(
        context: context,
        state: state,
        child: AddMemberPage(
          bloc: extra['bloc'] as GroupDetailBloc,
          currentMemberIds: extra['members'] as Set<String>,
        ),
      );
    },
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
// coverage:ignore-end
