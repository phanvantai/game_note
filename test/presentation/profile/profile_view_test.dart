import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/constants/constants.dart';
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
  const MethodChannel urlLauncherChannel = MethodChannel(
    'plugins.flutter.io/url_launcher',
  );

  setUpAll(() {
    registerFallbackValue(LoadProfileEvent());
    registerFallbackValue(ChangeAvatarProfileEvent());
    registerFallbackValue(DeleteAvatarProfileEvent());
    registerFallbackValue(SignOutProfileEvent());
    registerFallbackValue(UpdateFootballFeature(false));
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
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const ProfileView(),
            ),
            GoRoute(
              path: Routing.offline,
              builder: (context, _) => Scaffold(
                appBar: AppBar(
                  title: const Text('Offline page'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/'),
                  ),
                ),
                body: const Center(child: Text('Offline destination')),
              ),
            ),
            GoRoute(
              path: Routing.syncOfflineData,
              builder: (context, _) => Scaffold(
                appBar: AppBar(
                  title: const Text('Sync offline page'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/'),
                  ),
                ),
                body: const Center(child: Text('Sync offline destination')),
              ),
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
              path: Routing.feedback,
              builder: (context, _) => Scaffold(
                appBar: AppBar(
                  title: const Text('Feedback page'),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/'),
                  ),
                ),
                body: const Center(child: Text('Feedback destination')),
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
        fcmToken: '',
      ),
    );
  }

  void setLaunchUrlMock(List<MethodCall> calls) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, (call) async {
          calls.add(call);
          return true;
        });
  }

  Future<void> runWithPlatform(
    TargetPlatform platform,
    Future<void> Function() run,
  ) async {
    final previousPlatform = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = platform;
    try {
      await run();
    } finally {
      debugDefaultTargetPlatformOverride = previousPlatform;
    }
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

  testWidgets('profile tile offline confirm cancel does not navigate', (
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

    await tester.tap(find.text('Offline mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Offline page'), findsNothing);
    verifyNever(() => appBloc.add(any(that: isA<UpdateFootballFeature>())));
  });

  testWidgets('profile tile offline confirm accept navigates to offline', (
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

    await tester.tap(find.text('Offline mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Accept'));
    await tester.pumpAndSettle();

    expect(find.text('Offline destination'), findsOneWidget);
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

  testWidgets('menu tiles navigate to sync offline, setting, and feedback', (
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

    await tester.tap(find.text('Sync offline data'));
    await tester.pumpAndSettle();
    expect(find.text('Sync offline destination'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Other options'));
    await tester.pumpAndSettle();
    expect(find.text('Setting destination'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();
    expect(find.text('Feedback destination'), findsOneWidget);
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

  testWidgets('rate app opens play store URL on Android', (tester) async {
    final profileBloc = _MockProfileBloc();
    final appBloc = _MockAppBloc();
    final launchedCalls = <MethodCall>[];
    await runWithPlatform(TargetPlatform.android, () async {
      setLaunchUrlMock(launchedCalls);

      await tester.pumpWidget(
        buildProfile(
          profileBloc: profileBloc,
          appBloc: appBloc,
          profileInitialState: successProfile(),
          appState: const AppState(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rate'));
      await tester.pumpAndSettle();

      expect(launchedCalls, hasLength(1));
      expect(launchedCalls.first.method, 'launch');
      expect(launchedCalls.first.arguments['url'], playStoreUrl);
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, null);
  });

  testWidgets('rate app opens app store URL on iOS', (tester) async {
    final profileBloc = _MockProfileBloc();
    final appBloc = _MockAppBloc();
    final launchedCalls = <MethodCall>[];
    await runWithPlatform(TargetPlatform.iOS, () async {
      setLaunchUrlMock(launchedCalls);

      await tester.pumpWidget(
        buildProfile(
          profileBloc: profileBloc,
          appBloc: appBloc,
          profileInitialState: successProfile(),
          appState: const AppState(),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Rate'));
      await tester.pumpAndSettle();

      expect(launchedCalls, hasLength(1));
      expect(launchedCalls.first.method, 'launch');
      expect(launchedCalls.first.arguments['url'], appStoreUrl);
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(urlLauncherChannel, null);
  });

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

  testWidgets('hiding counter enables football feature after 10 taps', (
    tester,
  ) async {
    final profileBloc = _MockProfileBloc();
    final appBloc = _MockAppBloc();

    await tester.pumpWidget(
      buildProfile(
        profileBloc: profileBloc,
        appBloc: appBloc,
        profileInitialState: successProfile(),
        appState: const AppState(enableFootballFeature: false),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byIcon(Icons.info_outline).at(1));
      await tester.pump();
    }

    verify(
      () => appBloc.add(any(that: isA<UpdateFootballFeature>())),
    ).called(1);
  });

  testWidgets(
    'hiding counter disables football feature when currently enabled',
    (tester) async {
      final profileBloc = _MockProfileBloc();
      final appBloc = _MockAppBloc();

      await tester.pumpWidget(
        buildProfile(
          profileBloc: profileBloc,
          appBloc: appBloc,
          profileInitialState: successProfile(),
          appState: const AppState(enableFootballFeature: true),
        ),
      );
      await tester.pumpAndSettle();

      for (var i = 0; i < 10; i++) {
        await tester.tap(find.byIcon(Icons.info_outline).at(1));
        await tester.pump();
      }

      verify(
        () => appBloc.add(any(that: isA<UpdateFootballFeature>())),
      ).called(1);
    },
  );
}
