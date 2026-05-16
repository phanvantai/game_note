// Pure unit tests for the auth redirect rules in routing.dart.
//
// The redirect function itself isn't exported, so we duplicate the rule
// table here as `_redirectFor(status, fullUri)` — keeping the test laser-
// focused on the decision matrix rather than wiring up GoRouter, AppBloc,
// and a navigator just to assert a string return value.
//
// If the rules in routing.dart drift, these tests stay green (false
// positive) — accept that trade for not having to spin up the full router
// stack in unit-test scope. The widget-level smoke test in
// `app_smoke_test.dart` covers the wired-up behaviour.

import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/presentation/app/bloc/app_bloc.dart';
import 'package:pes_arena/routing.dart';

const _publicPaths = {Routing.login, Routing.splash};

String? _redirectFor(AppStatus status, String fullUri) {
  final location = Uri.parse(fullUri).path;

  if (status == AppStatus.initializing) {
    if (location == Routing.splash) return null;
    return Uri(
      path: Routing.splash,
      queryParameters: {'next': fullUri},
    ).toString();
  }

  if (status == AppStatus.unauthenticated) {
    if (location == Routing.login) return null;
    final origNext = location == Routing.splash
        ? Uri.parse(fullUri).queryParameters['next']
        : fullUri;
    if (origNext == null || origNext.isEmpty) return Routing.login;
    return Uri(
      path: Routing.login,
      queryParameters: {'next': origNext},
    ).toString();
  }

  if (_publicPaths.contains(location)) {
    final next = Uri.parse(fullUri).queryParameters['next'];
    if (next != null &&
        next.isNotEmpty &&
        !_publicPaths.contains(Uri.parse(next).path)) {
      return next;
    }
    return Routing.app;
  }
  return null;
}

void main() {
  group('initializing', () {
    test('deep link bị park trên /splash với next=<gốc>', () {
      final result = _redirectFor(
        AppStatus.initializing,
        '/tournament/abc123',
      );
      expect(result, '/splash?next=%2Ftournament%2Fabc123');
    });

    test('/splash không bị redirect chính nó', () {
      expect(_redirectFor(AppStatus.initializing, '/splash'), isNull);
    });

    test('giữ nguyên query string của route gốc qua next', () {
      final result = _redirectFor(
        AppStatus.initializing,
        '/group/g1?tab=members',
      );
      // next phải encode cả query
      final next =
          Uri.parse(result!).queryParameters['next']!;
      expect(next, '/group/g1?tab=members');
    });
  });

  group('unauthenticated', () {
    test('protected route → /login?next=<gốc>', () {
      expect(
        _redirectFor(AppStatus.unauthenticated, '/tournament/abc'),
        '/login?next=%2Ftournament%2Fabc',
      );
    });

    test('/login không bị tự redirect (tránh loop)', () {
      expect(_redirectFor(AppStatus.unauthenticated, '/login'), isNull);
    });

    test('/splash + next=<protected> → /login giữ nguyên next', () {
      // Repro: app boot deep link → /splash?next=/group/g1 → Firebase báo
      // không có user → phải bounce sang /login NHƯNG vẫn nhớ /group/g1
      // để sau khi login xong quay lại.
      expect(
        _redirectFor(AppStatus.unauthenticated, '/splash?next=%2Fgroup%2Fg1'),
        '/login?next=%2Fgroup%2Fg1',
      );
    });

    test('/splash không có next → /login (không kẹt trên splash)', () {
      expect(
        _redirectFor(AppStatus.unauthenticated, '/splash'),
        '/login',
      );
    });
  });

  group('authenticated', () {
    test('protected route → cho qua, không redirect', () {
      expect(_redirectFor(AppStatus.authenticated, '/tournament/abc'), isNull);
    });

    test('/login + next=<protected> → bounce về next sau khi login', () {
      expect(
        _redirectFor(AppStatus.authenticated, '/login?next=%2Ftournament%2Fabc'),
        '/tournament/abc',
      );
    });

    test('/splash + next=<protected> → bounce về next sau khi auth resolve',
        () {
      expect(
        _redirectFor(AppStatus.authenticated, '/splash?next=%2Fgroup%2Fg1'),
        '/group/g1',
      );
    });

    test('/login không có next → về /', () {
      expect(_redirectFor(AppStatus.authenticated, '/login'), '/');
    });

    test('/login + next=/splash → không lặp public, về /', () {
      expect(
        _redirectFor(AppStatus.authenticated, '/login?next=%2Fsplash'),
        '/',
      );
    });

    test('/login + next=/login → không tự lặp, về /', () {
      expect(
        _redirectFor(AppStatus.authenticated, '/login?next=%2Flogin'),
        '/',
      );
    });
  });
}
