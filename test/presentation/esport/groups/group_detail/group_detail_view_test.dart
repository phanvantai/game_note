import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart'; // ignore: unused_import
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/ultils.dart'; // ignore: unused_import
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/firebase/remote_config/gn_remote_config.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/group_detail_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Mocks / fakes
// ---------------------------------------------------------------------------

class _MockGroupDetailBloc
    extends MockBloc<GroupDetailEvent, GroupDetailState>
    implements GroupDetailBloc {}

class _MockRemoteConfig extends Mock implements GNRemoteConfig {}

class _FakeGroupDetailEvent extends Fake implements GroupDetailEvent {}

class _FakeGroupDetailState extends Fake implements GroupDetailState {}

// ---------------------------------------------------------------------------
// Factories
// ---------------------------------------------------------------------------

GNEsportGroup _group({
  String ownerId = 'owner1',
  List<String> members = const ['owner1'],
}) =>
    GNEsportGroup(
      id: 'G1',
      groupName: 'Test Group',
      ownerId: ownerId,
      members: members,
      description: '',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      status: 'active',
    );

GNUser _user(String id, {bool isPlaceholder = false}) => GNUser(
      id: id,
      displayName: 'User $id',
      email: null,
      phoneNumber: null,
      photoUrl: null,
      role: 'user',
      fcmToken: '',
      isPlaceholder: isPlaceholder,
    );

GroupDetailState _ownerState({List<GNUser> members = const []}) =>
    GroupDetailState(
      group: _group(ownerId: 'owner1'),
      members: members,
      currentUserId: 'owner1',
    );

GroupDetailState _memberState({List<GNUser> members = const []}) =>
    GroupDetailState(
      group: _group(ownerId: 'owner1', members: ['owner1', 'u2']),
      members: members,
      currentUserId: 'u2',
    );

// ---------------------------------------------------------------------------
// Router helper
// ---------------------------------------------------------------------------

Widget _wrapWithRouter(GroupDetailBloc bloc) {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => BlocProvider<GroupDetailBloc>.value(
          value: bloc,
          child: const GroupDetailView(),
        ),
      ),
      GoRoute(
        path: '/group/:groupId/add-member',
        builder: (context, state) => const Scaffold(
          body: Text('add-member page'),
        ),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: router,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _MockGroupDetailBloc bloc;
  late _MockRemoteConfig remoteConfig;

  setUpAll(() {
    registerFallbackValue(_FakeGroupDetailEvent());
    registerFallbackValue(_FakeGroupDetailState());
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    bloc = _MockGroupDetailBloc();
    remoteConfig = _MockRemoteConfig();
    when(() => remoteConfig.adsEnabled).thenReturn(false);
    getIt.registerSingleton<GNRemoteConfig>(remoteConfig);
  });

  tearDown(() => getIt.reset());

  testWidgets('render 3 tab labels', (tester) async {
    when(() => bloc.state).thenReturn(_ownerState());

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pump();

    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Thành viên'), findsOneWidget);
    expect(find.text('Giải đấu'), findsOneWidget);
  });

  testWidgets('initState dispatch LoadGroupOverview', (tester) async {
    when(() => bloc.state).thenReturn(_ownerState());

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(any(that: isA<LoadGroupOverview>())),
    ).called(1);
  });

  testWidgets(
      'initState dispatch LoadGroupLeagues cùng LoadGroupOverview (không phải khi chuyển tab)',
      (tester) async {
    when(() => bloc.state).thenReturn(_ownerState());

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    // LoadGroupLeagues được dispatch trong initState, không phải khi chuyển tab.
    verify(
      () => bloc.add(any(that: isA<LoadGroupLeagues>())),
    ).called(1);

    clearInteractions(bloc);

    // Chuyển sang tab Giải đấu → KHÔNG dispatch LoadGroupLeagues lần 2.
    await tester.tap(find.text('Giải đấu'));
    await tester.pumpAndSettle();

    verifyNever(() => bloc.add(any(that: isA<LoadGroupLeagues>())));
  });

  testWidgets('tab Thành viên: owner thấy nút Thêm thành viên',
      (tester) async {
    when(() => bloc.state).thenReturn(_ownerState());

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    // Switch to Thành viên tab
    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm thành viên'), findsOneWidget);
  });

  testWidgets('tab Thành viên: non-owner không thấy nút Thêm thành viên',
      (tester) async {
    when(() => bloc.state).thenReturn(_memberState());

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    // Switch to Thành viên tab
    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm thành viên'), findsNothing);
  });

  testWidgets('tab Thành viên: owner thấy nút xoá cho member khác',
      (tester) async {
    // owner1 is current user; u2 is another member
    // Since isCurrentUser checks FirebaseAuth and returns false in tests,
    // the owner (owner1) sees a remove button for all members (since none
    // of them returns isCurrentUser == true in test environment).
    when(() => bloc.state).thenReturn(
      _ownerState(members: [_user('owner1'), _user('u2')]),
    );

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();

    // u2 is not current user (FirebaseAuth returns null in tests) so remove
    // button should be visible for u2
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is IconButton &&
            (w.tooltip == 'Xoá thành viên' || w.tooltip == null),
      ),
      findsWidgets,
    );
    // Specifically verify the person_remove icon exists
    expect(find.byIcon(Icons.person_remove_outlined), findsWidgets);
  });

  testWidgets('tab Thành viên: non-owner thấy icon admin cho owner member',
      (tester) async {
    // non-owner (u2) view: owner1 should show admin icon
    when(() => bloc.state).thenReturn(
      _memberState(members: [_user('owner1'), _user('u2')]),
    );

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.admin_panel_settings_outlined), findsOneWidget);
  });

  testWidgets('AppBar: PopupMenuButton hiển thị khi non-owner member',
      (tester) async {
    // currentUserId = u2, u2 is in members list → currentUserIsMember = true
    // isOwner = false → should show PopupMenuButton
    final state = _memberState(members: [_user('owner1'), _user('u2')]);
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) => w is PopupMenuButton),
      findsOneWidget,
    );
  });

  testWidgets('AppBar: không có PopupMenuButton khi là owner', (tester) async {
    final state = _ownerState(members: [_user('owner1')]);
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    expect(
      find.byWidgetPredicate((w) => w is PopupMenuButton),
      findsNothing,
    );
  });

  testWidgets(
      'AppBar: Rời nhóm → hiện confirm dialog → confirm → dispatch RemoveMember',
      (tester) async {
    final state = _memberState(members: [_user('owner1'), _user('u2')]);
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    // Open popup menu
    await tester.tap(find.byWidgetPredicate((w) => w is PopupMenuButton));
    await tester.pumpAndSettle();

    // Tap 'Rời nhóm'
    await tester.tap(find.text('Rời nhóm'));
    await tester.pumpAndSettle();

    // Confirm dialog should be visible
    expect(find.text('Bạn có chắc chắn muốn rời nhóm?'), findsOneWidget);

    // Tap the confirm button (FilledButton with text 'Rời nhóm')
    // There are now two 'Rời nhóm' texts: dialog title and confirm button
    // Find the FilledButton's text
    final confirmButtons = find.descendant(
      of: find.byType(FilledButton),
      matching: find.text('Rời nhóm'),
    );
    await tester.tap(confirmButtons.last);
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(
        any(
          that: predicate<GroupDetailEvent>(
            (e) => e is RemoveMember && e.groupId == 'G1' && e.userId == 'u2',
          ),
        ),
      ),
    ).called(1);
  });
}
