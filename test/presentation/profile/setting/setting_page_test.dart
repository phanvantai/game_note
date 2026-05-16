import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:pes_arena/core/theme/theme_provider.dart';
import 'package:pes_arena/domain/repositories/esport/esport_group_repository.dart';
import 'package:pes_arena/domain/repositories/esport/esport_league_repository.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/profile/bloc/profile_bloc.dart';
import 'package:pes_arena/presentation/profile/setting/ownership_resolution_page.dart';
import 'package:pes_arena/presentation/profile/setting/setting_page.dart';
import 'package:pes_arena/routing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class _MockGNAuth extends Mock implements GNAuth {}

// ignore: subtype_of_sealed_class
class _MockFirebaseUser extends Mock implements User {}

class _MockGroupRepo extends Mock implements EsportGroupRepository {}

class _MockLeagueRepo extends Mock implements EsportLeagueRepository {}

void main() {
  late _MockProfileBloc profileBloc;
  late _MockGNAuth auth;
  late _MockFirebaseUser user;
  late _MockGroupRepo groupRepo;
  late _MockLeagueRepo leagueRepo;

  setUpAll(() {
    registerFallbackValue(DeleteProfileEvent());
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    profileBloc = _MockProfileBloc();
    auth = _MockGNAuth();
    user = _MockFirebaseUser();
    groupRepo = _MockGroupRepo();
    leagueRepo = _MockLeagueRepo();

    when(() => profileBloc.state).thenReturn(const ProfileState());
    when(() => user.uid).thenReturn('owner');
    when(() => auth.currentUser).thenReturn(user);
    when(() => auth.isSignInWithEmailAndPassword).thenReturn(false);
    when(
      () => groupRepo.getGroupsByOwnerId('owner'),
    ).thenAnswer((_) async => []);
    when(
      () => leagueRepo.getLeaguesByOwnerId('owner'),
    ).thenAnswer((_) async => []);

    getIt.registerFactory<ProfileBloc>(() => profileBloc);
    getIt.registerSingleton<GNAuth>(auth);
    getIt.registerSingleton<GNFirestore>(GNFirestore(FakeFirebaseFirestore()));
    getIt.registerFactory<EsportGroupRepository>(() => groupRepo);
    getIt.registerFactory<EsportLeagueRepository>(() => leagueRepo);
  });

  tearDown(() => getIt.reset());

  testWidgets('no ownership uses confirm dialog and dispatches delete', (
    tester,
  ) async {
    await tester.pumpWidget(await _app());

    await tester.tap(find.text('Xoá tài khoản'));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận'), findsOneWidget);

    await tester.tap(find.text('Xoá tài khoản').last);
    await tester.pumpAndSettle();

    verify(
      () => profileBloc.add(any(that: isA<DeleteProfileEvent>())),
    ).called(1);
  });

  testWidgets('cancel confirm dialog does not dispatch delete', (tester) async {
    await tester.pumpWidget(await _app());

    await tester.tap(find.text('Xoá tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();

    verifyNever(() => profileBloc.add(any(that: isA<DeleteProfileEvent>())));
  });

  testWidgets('ownership opens resolution page instead of confirm dialog', (
    tester,
  ) async {
    when(
      () => groupRepo.getGroupsByOwnerId('owner'),
    ).thenAnswer((_) async => [_group()]);

    await tester.pumpWidget(await _app());
    await tester.tap(find.text('Xoá tài khoản'));
    await tester.pumpAndSettle();

    expect(find.byType(OwnershipResolutionPage), findsOneWidget);
    expect(find.text('Xử lý quyền sở hữu'), findsOneWidget);
  });

  testWidgets('resolved ownership dispatches delete', (tester) async {
    final group = _group();
    when(
      () => groupRepo.getGroupsByOwnerId('owner'),
    ).thenAnswer((_) async => [group]);
    when(() => groupRepo.deactivateGroup(group.id)).thenAnswer((_) async {});

    await tester.pumpWidget(await _app());
    await tester.tap(find.text('Xoá tài khoản'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếp tục xoá tài khoản'));
    await tester.pumpAndSettle();

    verify(
      () => profileBloc.add(any(that: isA<DeleteProfileEvent>())),
    ).called(1);
  });

  testWidgets('shows loading while ownership check is pending', (tester) async {
    final completer = Completer<List<GNEsportGroup>>();
    when(
      () => groupRepo.getGroupsByOwnerId('owner'),
    ).thenAnswer((_) => completer.future);

    await tester.pumpWidget(await _app());
    await tester.tap(find.text('Xoá tài khoản'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    completer.complete([]);
    await tester.pumpAndSettle();
  });

  testWidgets('ownership check failure shows snackbar', (tester) async {
    when(() => groupRepo.getGroupsByOwnerId('owner')).thenThrow(Exception('x'));

    await tester.pumpWidget(await _app());
    await tester.tap(find.text('Xoá tài khoản'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Không thể kiểm tra quyền sở hữu'),
      findsOneWidget,
    );
  });

  testWidgets('theme switch and tile toggle theme mode', (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final themeNotifier = ThemeNotifier(prefs);
    await tester.pumpWidget(_appWithNotifier(themeNotifier));

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(themeNotifier.isDark, true);

    await tester.tap(find.text('Chế độ tối'));
    await tester.pumpAndSettle();
    expect(themeNotifier.isDark, false);
  });

  testWidgets('settings navigation tiles use configured routes', (
    tester,
  ) async {
    when(() => auth.isSignInWithEmailAndPassword).thenReturn(true);

    await tester.pumpWidget(await _routerApp());
    await tester.tap(find.text('Cập nhật thông tin'));
    await tester.pumpAndSettle();
    expect(find.text('Update profile route'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đổi mật khẩu'));
    await tester.pumpAndSettle();
    expect(find.text('Change password route'), findsOneWidget);
  });
}

Future<Widget> _app() async {
  final prefs = await SharedPreferences.getInstance();
  return _appWithNotifier(ThemeNotifier(prefs));
}

Widget _appWithNotifier(ThemeNotifier themeNotifier) {
  return ChangeNotifierProvider.value(
    value: themeNotifier,
    child: const MaterialApp(home: SettingPage()),
  );
}

Future<Widget> _routerApp() async {
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SettingPage()),
      GoRoute(
        path: Routing.updateProfile,
        builder: (context, state) => Scaffold(
          appBar: AppBar(),
          body: const Text('Update profile route'),
        ),
      ),
      GoRoute(
        path: Routing.changePassword,
        builder: (context, state) => Scaffold(
          appBar: AppBar(),
          body: const Text('Change password route'),
        ),
      ),
    ],
  );
  return ChangeNotifierProvider(
    create: (_) => ThemeNotifier(prefs),
    child: MaterialApp.router(routerConfig: router),
  );
}

GNEsportGroup _group() {
  final now = DateTime(2026, 5, 10);
  return GNEsportGroup(
    id: 'G1',
    groupName: 'Nhóm test',
    ownerId: 'owner',
    members: const ['owner'],
    description: '',
    createdAt: now,
    updatedAt: now,
    status: 'active',
  );
}
