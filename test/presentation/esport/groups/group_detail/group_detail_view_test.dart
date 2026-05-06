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
  List<String> deactivatedMembers = const [],
}) =>
    GNEsportGroup(
      id: 'G1',
      groupName: 'Test Group',
      ownerId: ownerId,
      members: members,
      deactivatedMembers: deactivatedMembers,
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

GroupDetailState _ownerState({
  List<GNUser> members = const [],
  List<String> deactivatedMembers = const [],
}) =>
    GroupDetailState(
      group: _group(
        ownerId: 'owner1',
        members: ['owner1', ...members.map((u) => u.id)],
        deactivatedMembers: deactivatedMembers,
      ),
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

  testWidgets('render 2 tab labels', (tester) async {
    when(() => bloc.state).thenReturn(_ownerState());

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pump();

    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Thành viên'), findsOneWidget);
    expect(find.text('Giải đấu'), findsNothing);
  });

  testWidgets('initState dispatch LoadGroupOverview', (tester) async {
    when(() => bloc.state).thenReturn(_ownerState());

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(any(that: isA<LoadGroupOverview>())),
    ).called(1);
  });

  testWidgets('initState dispatch LoadGroupLeagues cùng LoadGroupOverview',
      (tester) async {
    when(() => bloc.state).thenReturn(_ownerState());

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    // LoadGroupLeagues được dispatch trong initState (vẫn cần cho year filter của overview).
    verify(
      () => bloc.add(any(that: isA<LoadGroupLeagues>())),
    ).called(1);
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

  testWidgets('tab Thành viên: owner thấy popup menu cho member khác',
      (tester) async {
    when(() => bloc.state).thenReturn(
      _ownerState(members: [_user('owner1'), _user('u2')]),
    );

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();

    // Owner sees a more_vert popup menu button for non-owner members.
    expect(find.byIcon(Icons.more_vert), findsWidgets);
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
      'tab Thành viên: badge "Không hoạt động" hiện khi member trong deactivatedMembers',
      (tester) async {
    final state = _ownerState(
      members: [_user('owner1'), _user('u2')],
      deactivatedMembers: ['u2'],
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();

    expect(find.text('Không hoạt động'), findsOneWidget);
  });

  testWidgets(
      'tab Thành viên: không có badge khi không có deactivated member',
      (tester) async {
    final state = _ownerState(
      members: [_user('owner1'), _user('u2')],
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();

    expect(find.text('Không hoạt động'), findsNothing);
  });

  testWidgets(
      'tab Thành viên: popup menu owner có đủ 3 option cho active member',
      (tester) async {
    final state = _ownerState(
      members: [_user('owner1'), _user('u2')],
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();

    // Open the popup menu for u2 (more_vert icon)
    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();

    expect(find.text('Ngừng hoạt động'), findsOneWidget);
    expect(find.text('Xoá khỏi nhóm'), findsOneWidget);
  });

  testWidgets(
      'tab Thành viên: popup menu owner hiện "Kích hoạt lại" cho deactivated member',
      (tester) async {
    final state = _ownerState(
      members: [_user('owner1'), _user('u2')],
      deactivatedMembers: ['u2'],
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();

    expect(find.text('Kích hoạt lại'), findsOneWidget);
    expect(find.text('Xoá khỏi nhóm'), findsOneWidget);
  });

  testWidgets(
      'tab Thành viên: chọn "Ngừng hoạt động" → dispatch ToggleMemberDeactivation',
      (tester) async {
    final state = _ownerState(
      members: [_user('owner1'), _user('u2')],
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream.value(state), initialState: state);

    await tester.pumpWidget(_wrapWithRouter(bloc));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Thành viên'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert).last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ngừng hoạt động'));
    await tester.pumpAndSettle();

    verify(
      () => bloc.add(
        any(
          that: predicate<GroupDetailEvent>(
            (e) =>
                e is ToggleMemberDeactivation &&
                e.userId == 'u2' &&
                e.deactivate == true,
          ),
        ),
      ),
    ).called(1);
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
