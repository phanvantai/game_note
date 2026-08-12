import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/app/bloc/app_bloc.dart';
import 'package:pes_arena/presentation/profile/bloc/profile_bloc.dart';
import 'package:pes_arena/presentation/profile/profile_view.dart';
import 'package:pes_arena/routing.dart';

class _MockAppBloc extends MockBloc<AppEvent, AppState> implements AppBloc {}

class _MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class _FailingCacheManager extends Mock implements BaseCacheManager {}

void main() {
  const MethodChannel packageInfoChannel = MethodChannel(
    'dev.fluttercommunity.plus/package_info',
  );
  setUpAll(() {
    registerFallbackValue(InitApp());
    registerFallbackValue(LoadProfileEvent());
    registerFallbackValue(ChangeAvatarProfileEvent());
    registerFallbackValue(DeleteAvatarProfileEvent());
    registerFallbackValue(SignOutProfileEvent());
  });

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, (call) async {
          if (call.method == 'getAll') {
            return <String, String>{
              'appName': 'pes_arena',
              'packageName': 'com.example.pes_arena',
              'version': '1.0.0',
              'buildNumber': '1',
            };
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, null);
  });

  Widget buildProfile({
    required ProfileBloc profileBloc,
    required AppBloc appBloc,
    required ProfileState profileInitialState,
    required AppState appState,
    Stream<ProfileState>? profileStateStream,
    Locale locale = const Locale('en'),
  }) {
    when(() => profileBloc.state).thenReturn(profileInitialState);
    when(() => appBloc.state).thenReturn(appState);
    whenListen(
      profileBloc,
      profileStateStream ?? const Stream<ProfileState>.empty(),
      initialState: profileInitialState,
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<AppBloc>.value(value: appBloc),
        BlocProvider<ProfileBloc>.value(value: profileBloc),
      ],
      child: MaterialApp.router(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const ProfileView(),
            ),
            GoRoute(
              path: Routing.setting,
              builder: (context, _) => Scaffold(
                appBar: AppBar(
                  title: const Text('Setting page'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/'),
                  ),
                ),
                body: const Center(child: Text('Setting destination')),
              ),
            ),
            GoRoute(
              path: Routing.updateProfile,
              builder: (context, _) => Scaffold(
                appBar: AppBar(
                  title: const Text('Update profile page'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                body: const Center(child: Text('Update profile destination')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ProfileState successProfile({
    String email = 'user@example.com',
    String displayName = 'Player one',
    String photoUrl = '',
  }) {
    return ProfileState(
      viewStatus: ViewStatus.success,
      user: GNUser(
        id: 'u1',
        displayName: displayName,
        phoneNumber: null,
        email: email,
        photoUrl: photoUrl,
        role: 'user',
      ),
    );
  }

  testWidgets('shows loading indicator when profile state is loading', (
    tester,
  ) async {
    final profileBloc = _MockProfileBloc();
    final appBloc = _MockAppBloc();

    await tester.pumpWidget(
      buildProfile(
        profileBloc: profileBloc,
        appBloc: appBloc,
        profileInitialState: const ProfileState(viewStatus: ViewStatus.loading),
        appState: const AppState(),
      ),
    );
    await tester.pump();

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    verify(() => profileBloc.add(LoadProfileEvent())).called(1);
  });

  testWidgets('shows snackbar when profile emits an error state', (
    tester,
  ) async {
    final profileBloc = _MockProfileBloc();
    final appBloc = _MockAppBloc();
    final errorState = const ProfileState(
      viewStatus: ViewStatus.failure,
      error: 'Could not load profile',
    );

    await tester.pumpWidget(
      buildProfile(
        profileBloc: profileBloc,
        appBloc: appBloc,
        profileInitialState: const ProfileState(viewStatus: ViewStatus.success),
        appState: const AppState(),
        profileStateStream: Stream<ProfileState>.fromIterable([errorState]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Could not load profile'), findsOneWidget);
  });

  testWidgets('open avatar menu and dispatch change avatar event', (
    tester,
  ) async {
    final profileBloc = _MockProfileBloc();
    final appBloc = _MockAppBloc();

    await tester.pumpWidget(
      buildProfile(
        profileBloc: profileBloc,
        appBloc: appBloc,
        profileInitialState: successProfile(),
        appState: const AppState(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change avatar'));
    await tester.pumpAndSettle();

    verify(
      () => profileBloc.add(any(that: isA<ChangeAvatarProfileEvent>())),
    ).called(1);
  });

  testWidgets('open avatar menu and dispatch delete avatar event', (
    tester,
  ) async {
    final profileBloc = _MockProfileBloc();
    final appBloc = _MockAppBloc();

    await tester.pumpWidget(
      buildProfile(
        profileBloc: profileBloc,
        appBloc: appBloc,
        profileInitialState: successProfile(),
        appState: const AppState(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.camera_alt));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete avatar'));
    await tester.pumpAndSettle();

    verify(
      () => profileBloc.add(any(that: isA<DeleteAvatarProfileEvent>())),
    ).called(1);
  });

  testWidgets('profile shows only approved account actions', (tester) async {
    final profileBloc = _MockProfileBloc();
    final appBloc = _MockAppBloc();

    await tester.pumpWidget(
      buildProfile(
        profileBloc: profileBloc,
        appBloc: appBloc,
        profileInitialState: successProfile(),
        appState: const AppState(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Offline mode'), findsNothing);
    expect(find.text('Sync offline data'), findsNothing);
    expect(find.text('Rate'), findsNothing);
    expect(find.text('Feedback'), findsNothing);
    expect(find.text('Other options'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('sign-out confirm cancel does not dispatch', (tester) async {
    final profileBloc = _MockProfileBloc();
    final appBloc = _MockAppBloc();

    await tester.pumpWidget(
      buildProfile(
        profileBloc: profileBloc,
        appBloc: appBloc,
        profileInitialState: successProfile(),
        appState: const AppState(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    verifyNever(() => profileBloc.add(any(that: isA<SignOutProfileEvent>())));
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('sign-out confirm accept dispatches sign out event', (
    tester,
  ) async {
    final profileBloc = _MockProfileBloc();
    final appBloc = _MockAppBloc();

    await tester.pumpWidget(
      buildProfile(
        profileBloc: profileBloc,
        appBloc: appBloc,
        profileInitialState: successProfile(),
        appState: const AppState(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();

    verify(
      () => profileBloc.add(any(that: isA<SignOutProfileEvent>())),
    ).called(1);
  });

  testWidgets('Other options navigates to settings', (tester) async {
    final profileBloc = _MockProfileBloc();
    final appBloc = _MockAppBloc();

    await tester.pumpWidget(
      buildProfile(
        profileBloc: profileBloc,
        appBloc: appBloc,
        profileInitialState: successProfile(),
        appState: const AppState(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Other options'));
    await tester.pumpAndSettle();
    expect(find.text('Setting destination'), findsOneWidget);
  });

  testWidgets(
    'edit profile tile opens update profile screen and reloads profile',
    (tester) async {
      final profileBloc = _MockProfileBloc();
      final appBloc = _MockAppBloc();

      await tester.pumpWidget(
        buildProfile(
          profileBloc: profileBloc,
          appBloc: appBloc,
          profileInitialState: successProfile(),
          appState: const AppState(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Update profile destination'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      verify(
        () => profileBloc.add(any(that: isA<LoadProfileEvent>())),
      ).called(2);
    },
  );

  testWidgets(
    'avatar error fallback displays default icon when image load fails',
    (tester) async {
      final profileBloc = _MockProfileBloc();
      final appBloc = _MockAppBloc();
      final cacheManager = _FailingCacheManager();
      final originalCacheManager =
          CachedNetworkImageProvider.defaultCacheManager;

      when(
        () => cacheManager.getFileFromCache(any()),
      ).thenAnswer((_) async => null);
      when(
        () => cacheManager.getFileStream(
          any(),
          key: any(named: 'key'),
          headers: any(named: 'headers'),
          withProgress: any(named: 'withProgress'),
        ),
      ).thenAnswer(
        (_) => Stream<FileResponse>.error(Exception('Image failed')),
      );

      CachedNetworkImageProvider.defaultCacheManager = cacheManager;

      try {
        await tester.pumpWidget(
          buildProfile(
            profileBloc: profileBloc,
            appBloc: appBloc,
            profileInitialState: successProfile(
              photoUrl: 'https://example.com/avatar.png',
            ),
            appState: const AppState(),
          ),
        );
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byIcon(Icons.person), findsOneWidget);
      } finally {
        CachedNetworkImageProvider.defaultCacheManager = originalCacheManager;
      }
    },
  );

  testWidgets('Version label is localized in Vietnamese', (tester) async {
    final profileBloc = _MockProfileBloc();
    final appBloc = _MockAppBloc();

    await tester.pumpWidget(
      buildProfile(
        profileBloc: profileBloc,
        appBloc: appBloc,
        profileInitialState: successProfile(),
        appState: const AppState(),
        locale: const Locale('vi'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Phiên bản'), findsOneWidget);
  });

  testWidgets('tapping Version repeatedly keeps Profile passive', (
    tester,
  ) async {
    final profileBloc = _MockProfileBloc();
    final appBloc = _MockAppBloc();

    await tester.pumpWidget(
      buildProfile(
        profileBloc: profileBloc,
        appBloc: appBloc,
        profileInitialState: successProfile(),
        appState: const AppState(),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 10; i++) {
      await tester.tap(find.text('Version'));
      await tester.pump();
    }

    expect(find.text('Player profile'), findsOneWidget);
    expect(find.text('Other options'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(() => appBloc.add(any()));
  });
}
