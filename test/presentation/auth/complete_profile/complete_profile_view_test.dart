import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/domain/repositories/user_repository.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/app/bloc/app_bloc.dart';
import 'package:pes_arena/presentation/auth/complete_profile/complete_profile_page.dart';
import 'package:pes_arena/routing.dart';

class _MockAppBloc extends Mock implements AppBloc {}

class _MockUserRepository extends Mock implements UserRepository {}

Widget _buildPage({
  required UserRepository? userRepository,
  String? nextLocation,
}) {
  final router = GoRouter(
    initialLocation: Routing.completeProfile,
    routes: [
      GoRoute(
        path: Routing.app,
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('HOME_SCREEN'))),
      ),
      GoRoute(
        path: Routing.groups,
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('GROUP_SCREEN'))),
      ),
      GoRoute(
        path: Routing.completeProfile,
        builder: (_, state) => CompleteProfilePage(
          userRepository: userRepository,
          nextLocation: nextLocation,
        ),
      ),
    ],
  );

  return MaterialApp.router(
    locale: const Locale('vi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    routerConfig: router,
  );
}

void main() {
  late _MockUserRepository repository;
  late _MockAppBloc appBloc;

  setUp(() async {
    await getIt.reset();
    repository = _MockUserRepository();
    appBloc = _MockAppBloc();
  });

  tearDown(() async {
    await getIt.reset();
  });

  testWidgets(
    'successful submit updates profile with trimmed display name and shows loading',
    (tester) async {
      final submitCompleter = Completer<void>();
      when(
        () => repository.updateProfile(
          displayName: any(named: 'displayName'),
          phoneNumber: any(named: 'phoneNumber'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) => submitCompleter.future);

      await tester.pumpWidget(_buildPage(userRepository: repository));
      await tester.enterText(find.byType(TextField), '  Alice Nguyen  ');
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      submitCompleter.complete();
      await tester.pumpAndSettle();

      verify(
        () => repository.updateProfile(
          displayName: 'Alice Nguyen',
          phoneNumber: null,
          email: null,
        ),
      ).called(1);
    },
  );

  testWidgets(
    'when AppBloc is registered, submit dispatches RefreshCurrentUser and navigates safe next',
    (tester) async {
      when(
        () => repository.updateProfile(
          displayName: any(named: 'displayName'),
          phoneNumber: any(named: 'phoneNumber'),
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async {});
      getIt.registerSingleton<AppBloc>(appBloc);

      await tester.pumpWidget(
        _buildPage(userRepository: repository, nextLocation: Routing.groups),
      );

      await tester.enterText(find.byType(TextField), '  Bob Tran  ');
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      verify(
        () => repository.updateProfile(
          displayName: 'Bob Tran',
          phoneNumber: null,
          email: null,
        ),
      ).called(1);
      verify(() => appBloc.add(RefreshCurrentUser())).called(1);
      expect(find.text('GROUP_SCREEN'), findsOneWidget);
    },
  );

  testWidgets('shows error and re-enables submit on repository failure', (
    tester,
  ) async {
    when(
      () => repository.updateProfile(
        displayName: any(named: 'displayName'),
        phoneNumber: any(named: 'phoneNumber'),
        email: any(named: 'email'),
      ),
    ).thenAnswer((_) => Future<void>.error(Exception('network error')));

    await tester.pumpWidget(_buildPage(userRepository: repository));
    await tester.enterText(find.byType(TextField), 'Failure Case');
    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    await tester.pump();

    expect(find.text('Exception: network error'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('submits via text field keyboard action', (tester) async {
    when(
      () => repository.updateProfile(
        displayName: any(named: 'displayName'),
        phoneNumber: any(named: 'phoneNumber'),
        email: any(named: 'email'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(_buildPage(userRepository: repository));
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), '  Enter Submit  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    verify(
      () => repository.updateProfile(
        displayName: 'Enter Submit',
        phoneNumber: null,
        email: null,
      ),
    ).called(1);
  });

  testWidgets('uses getIt fallback when userRepository is omitted', (
    tester,
  ) async {
    getIt.registerSingleton<UserRepository>(repository);
    when(
      () => repository.updateProfile(
        displayName: any(named: 'displayName'),
        phoneNumber: any(named: 'phoneNumber'),
        email: any(named: 'email'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(_buildPage(userRepository: null));
    await tester.enterText(find.byType(TextField), '  Fallback Repo  ');
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    verify(
      () => repository.updateProfile(
        displayName: 'Fallback Repo',
        phoneNumber: null,
        email: null,
      ),
    ).called(1);
  });

  testWidgets('requires a display name before saving', (tester) async {
    await tester.pumpWidget(_buildPage(userRepository: repository));

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('Tên hiển thị không được để trống'), findsOneWidget);
    verifyNever(
      () => repository.updateProfile(
        displayName: any(named: 'displayName'),
        phoneNumber: any(named: 'phoneNumber'),
        email: any(named: 'email'),
      ),
    );
  });

  testWidgets('disposes controller when page is removed', (tester) async {
    await tester.pumpWidget(_buildPage(userRepository: repository));
    await tester.enterText(find.byType(TextField), 'Temp');
    await tester.pump();

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: const Scaffold(body: Center(child: Text('DONE'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DONE'), findsOneWidget);
  });
}
