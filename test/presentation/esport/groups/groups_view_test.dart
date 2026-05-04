import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/presentation/esport/groups/bloc/group_bloc.dart';
import 'package:pes_arena/presentation/esport/groups/groups_view.dart';
import 'package:pes_arena/presentation/notification/bloc/notification_bloc.dart';

class _MockGroupBloc extends MockBloc<GroupEvent, GroupState>
    implements GroupBloc {}

class _MockGroupState extends Mock implements GroupState {}

class _MockNotificationBloc
    extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

GNEsportGroup _group(String id, String name) {
  return GNEsportGroup(
    id: id,
    groupName: name,
    ownerId: 'u1',
    members: const ['u1'],
    description: '',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    status: 'active',
  );
}

Widget _wrap({
  required GroupBloc groupBloc,
  required NotificationBloc notificationBloc,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<GroupBloc>.value(value: groupBloc),
      BlocProvider<NotificationBloc>.value(value: notificationBloc),
    ],
    child: MaterialApp.router(
      routerConfig: GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const GroupsView(),
          ),
          GoRoute(
            path: '/notification',
            builder: (context, state) => const Text('notification page'),
          ),
          GoRoute(
            path: '/group/:groupId',
            builder: (context, state) => Scaffold(
              body: FilledButton(
                onPressed: () => context.pop(),
                child: Text('group ${state.pathParameters['groupId']}'),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

_MockGroupState _state({
  ViewStatus status = ViewStatus.success,
  List<GNEsportGroup> userGroups = const [],
  List<GNEsportGroup> otherGroups = const [],
}) {
  final state = _MockGroupState();
  when(() => state.viewStatus).thenReturn(status);
  when(() => state.userGroups).thenReturn(userGroups);
  when(() => state.otherGroups).thenReturn(otherGroups);
  return state;
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const CreateEsportGroup(groupName: 'fallback', description: ''),
    );
    registerFallbackValue(GetEsportGroups());
  });

  tearDown(resetShowToast);

  testWidgets('standalone render appbar và tabs', (tester) async {
    final groupBloc = _MockGroupBloc();
    final notificationBloc = _MockNotificationBloc();
    final state = _state();
    when(() => groupBloc.state).thenReturn(state);
    when(() => notificationBloc.state).thenReturn(const NotificationState());

    await tester.pumpWidget(
      _wrap(groupBloc: groupBloc, notificationBloc: notificationBloc),
    );

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Nhóm của tôi'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsNothing);
  });

  testWidgets('loading và empty states', (tester) async {
    final groupBloc = _MockGroupBloc();
    final notificationBloc = _MockNotificationBloc();
    final state = _state(status: ViewStatus.loading);
    when(() => groupBloc.state).thenReturn(state);
    when(() => notificationBloc.state).thenReturn(const NotificationState());

    await tester.pumpWidget(
      _wrap(groupBloc: groupBloc, notificationBloc: notificationBloc),
    );

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Không có nhóm nào'), findsOneWidget);
    await tester.tap(find.text('Nhóm khác'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Không có nhóm nào'), findsOneWidget);
  });

  testWidgets('create group dialog gửi event và đóng dialog', (tester) async {
    final groupBloc = _MockGroupBloc();
    final notificationBloc = _MockNotificationBloc();
    final state = _state();
    when(() => groupBloc.state).thenReturn(state);
    when(() => notificationBloc.state).thenReturn(const NotificationState());

    await tester.pumpWidget(
      _wrap(groupBloc: groupBloc, notificationBloc: notificationBloc),
    );

    await tester.tap(find.byTooltip('Tạo nhóm'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo nhóm mới'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Team A');
    await tester.enterText(find.byType(TextField).at(1), 'Desc');
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo nhóm'));
    await tester.pumpAndSettle();

    verify(
      () => groupBloc.add(
        const CreateEsportGroup(groupName: 'Team A', description: 'Desc'),
      ),
    ).called(1);
    expect(find.text('Tạo nhóm mới'), findsNothing);
  });

  testWidgets('create group dialog cancel và validate tên rỗng', (
    tester,
  ) async {
    final groupBloc = _MockGroupBloc();
    final notificationBloc = _MockNotificationBloc();
    final state = _state();
    var toastMessage = '';
    setShowToastImpl(
      (message, {gravity = ToastGravity.BOTTOM}) => toastMessage = message,
    );
    when(() => groupBloc.state).thenReturn(state);
    when(() => notificationBloc.state).thenReturn(const NotificationState());

    await tester.pumpWidget(
      _wrap(groupBloc: groupBloc, notificationBloc: notificationBloc),
    );

    await tester.tap(find.byTooltip('Tạo nhóm'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Huỷ'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo nhóm mới'), findsNothing);

    await tester.tap(find.byTooltip('Tạo nhóm'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Tạo nhóm'));
    await tester.pump();

    expect(toastMessage, 'Tên nhóm không được để trống');
    verifyNever(() => groupBloc.add(any(that: isA<CreateEsportGroup>())));
  });

  testWidgets('render group lists và refresh sau khi quay về từ detail', (
    tester,
  ) async {
    final groupBloc = _MockGroupBloc();
    final notificationBloc = _MockNotificationBloc();
    final state = _state(
      userGroups: [_group('g1', 'Group One')],
      otherGroups: [_group('g2', 'Group Two')],
    );
    when(() => groupBloc.state).thenReturn(state);
    when(() => notificationBloc.state).thenReturn(const NotificationState());

    await tester.pumpWidget(
      _wrap(groupBloc: groupBloc, notificationBloc: notificationBloc),
    );

    expect(find.text('Group One'), findsOneWidget);
    await tester.tap(find.text('Group One'));
    await tester.pumpAndSettle();
    expect(find.text('group g1'), findsOneWidget);

    await tester.tap(find.text('group g1'));
    await tester.pumpAndSettle();

    verify(() => groupBloc.add(any(that: isA<GetEsportGroups>()))).called(1);

    await tester.tap(find.text('Nhóm khác'));
    await tester.pumpAndSettle();
    expect(find.text('Group Two'), findsOneWidget);
  });
}
