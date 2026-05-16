import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pes_arena/presentation/common/smart_back.dart';
import 'package:pes_arena/routing.dart';

void main() {
  // Repro the web-deep-link scenario: router stack has exactly one entry,
  // so canPop() is false. Default AppBar back arrow would be missing here.
  GoRouter buildRouter({required String initialLocation}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(
            body: Center(child: Text('HOME')),
          ),
        ),
        GoRoute(
          path: '/tournament/:id',
          builder: (_, _) => Scaffold(
            appBar: AppBar(
              leading: const SmartBackButton(),
              title: const Text('Detail'),
            ),
            body: const Center(child: Text('DETAIL')),
          ),
        ),
      ],
    );
  }

  testWidgets(
      'SmartBackButton trên deep-link route (stack=1) bấm → về fallback /',
      (tester) async {
    final router = buildRouter(initialLocation: '/tournament/abc');

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // Detail page rendered with our back button visible (default AppBar
    // would NOT have shown one because canPop is false).
    expect(find.text('DETAIL'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('DETAIL'), findsNothing);
  });

  testWidgets(
      'SmartBackButton sau khi user push từ trong app → pop về trang trước',
      (tester) async {
    final router = buildRouter(initialLocation: '/');
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    // Push detail từ home (simulating in-app navigation, không phải deep link).
    router.push('/tournament/abc');
    await tester.pumpAndSettle();
    expect(find.text('DETAIL'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('SmartBackButton custom fallback override Routing.app',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/tournament/abc',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('HOME')),
        ),
        GoRoute(
          path: '/groups',
          builder: (_, _) => const Scaffold(body: Text('GROUPS')),
        ),
        GoRoute(
          path: '/tournament/:id',
          builder: (_, _) => Scaffold(
            appBar: AppBar(
              leading: const SmartBackButton(fallback: '/groups'),
              title: const Text('Detail'),
            ),
            body: const Text('DETAIL'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('GROUPS'), findsOneWidget);
  });

  test('Routing.app fallback constant đúng "/"', () {
    expect(Routing.app, '/');
  });
}
