import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart'; // ignore: unused_import
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart'; // ignore: unused_import
import 'package:pes_arena/firebase/firestore/esport/group/gn_esport_group.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/add_member_page.dart';
import 'package:pes_arena/presentation/esport/groups/group_detail/bloc/group_detail_bloc.dart';
import 'package:pes_arena/presentation/users/bloc/user_bloc.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockGroupDetailBloc
    extends MockBloc<GroupDetailEvent, GroupDetailState>
    implements GroupDetailBloc {}

class _MockUserBloc extends MockBloc<UserEvent, UserState>
    implements UserBloc {}

// Fallback values for mocktail
class _FakeGroupDetailEvent extends Fake implements GroupDetailEvent {}

class _FakeUserEvent extends Fake implements UserEvent {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

GNEsportGroup _group() => GNEsportGroup(
      id: 'G1',
      groupName: 'Test',
      ownerId: 'owner1',
      members: const ['owner1'],
      description: '',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      status: 'active',
    );

GroupDetailState _detailState() => GroupDetailState(
      group: _group(),
      currentUserId: 'owner1',
    );

UserState _userState({List<GNUser> users = const []}) =>
    UserState(viewStatus: ViewStatus.success, users: users);

GNUser _user({
  required String id,
  required String displayName,
  bool isPlaceholder = false,
}) =>
    GNUser(
      id: id,
      displayName: displayName,
      phoneNumber: null,
      email: null,
      photoUrl: null,
      role: 'user',
      fcmToken: '',
      isPlaceholder: isPlaceholder,
    );

Widget _wrap(AddMemberPage page) => MaterialApp(home: page);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late _MockGroupDetailBloc groupBloc;
  late _MockUserBloc userBloc;

  setUpAll(() {
    registerFallbackValue(_FakeGroupDetailEvent());
    registerFallbackValue(_FakeUserEvent());
  });

  setUp(() {
    groupBloc = _MockGroupDetailBloc();
    userBloc = _MockUserBloc();

    when(() => groupBloc.state).thenReturn(_detailState());
    when(() => userBloc.state).thenReturn(_userState());
  });

  AddMemberPage page({Set<String> memberIds = const {}}) => AddMemberPage(
        bloc: groupBloc,
        currentMemberIds: memberIds,
        userBloc: userBloc,
      );

  group('AddMemberPage', () {
    testWidgets('render AppBar Thêm thành viên', (tester) async {
      await tester.pumpWidget(_wrap(page()));
      await tester.pump();

      expect(find.text('Thêm thành viên'), findsOneWidget);
    });

    testWidgets('search field onChange dispatch SearchUser', (tester) async {
      await tester.pumpWidget(_wrap(page()));
      await tester.pump();

      await tester.enterText(find.byType(TextField).first, 'abc');

      verify(() => userBloc.add(const SearchUser('abc'))).called(1);
    });

    testWidgets('placeholder tile hiển thị collapsed ban đầu', (tester) async {
      await tester.pumpWidget(_wrap(page()));
      await tester.pump();

      expect(find.text('Tạo người chơi mới (placeholder)'), findsOneWidget);
    });

    testWidgets('tap tile mở rộng form nhập tên', (tester) async {
      await tester.pumpWidget(_wrap(page()));
      await tester.pump();

      await tester.tap(find.text('Tạo người chơi mới (placeholder)'));
      await tester.pump();

      expect(find.widgetWithText(TextField, 'Tên người chơi'), findsOneWidget);
      expect(find.text('Huỷ'), findsOneWidget);
      expect(find.text('Tạo'), findsOneWidget);
    });

    testWidgets('form expanded: Huỷ button collapse lại', (tester) async {
      await tester.pumpWidget(_wrap(page()));
      await tester.pump();

      // Expand
      await tester.tap(find.text('Tạo người chơi mới (placeholder)'));
      await tester.pump();

      // Tap Huỷ
      await tester.tap(find.text('Huỷ'));
      await tester.pump();

      // Should be collapsed again
      expect(find.text('Tạo người chơi mới (placeholder)'), findsOneWidget);
      expect(find.text('Huỷ'), findsNothing);
    });

    testWidgets('form expanded: Tạo với tên rỗng không dispatch',
        (tester) async {
      await tester.pumpWidget(_wrap(page()));
      await tester.pump();

      // Expand
      await tester.tap(find.text('Tạo người chơi mới (placeholder)'));
      await tester.pump();

      // Tap Tạo without entering text
      await tester.tap(find.text('Tạo'));
      await tester.pump();

      verifyNever(
          () => groupBloc.add(any(that: isA<AddPlaceholderMember>())));
    });

    testWidgets(
        'form expanded: Tạo với tên hợp lệ dispatch AddPlaceholderMember và pop',
        (tester) async {
      await tester.pumpWidget(_wrap(page()));
      await tester.pump();

      // Expand
      await tester.tap(find.text('Tạo người chơi mới (placeholder)'));
      await tester.pump();

      // Enter text
      final nameField =
          find.widgetWithText(TextField, 'Tên người chơi');
      await tester.enterText(nameField, 'Test Player');
      await tester.pump();

      // Tap Tạo
      await tester.tap(find.text('Tạo'));
      await tester.pump();

      verify(() => groupBloc
          .add(const AddPlaceholderMember('G1', 'Test Player'))).called(1);
    });

    testWidgets(
        'form expanded: submit keyboard dispatch AddPlaceholderMember và pop',
        (tester) async {
      await tester.pumpWidget(_wrap(page()));
      await tester.pump();

      // Expand
      await tester.tap(find.text('Tạo người chơi mới (placeholder)'));
      await tester.pump();

      // Enter text and submit via keyboard
      final nameField =
          find.widgetWithText(TextField, 'Tên người chơi');
      await tester.enterText(nameField, 'Test Player');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      verify(() => groupBloc
          .add(const AddPlaceholderMember('G1', 'Test Player'))).called(1);
    });

    testWidgets('user list hiển thị user không phải member', (tester) async {
      final user = _user(id: 'u1', displayName: 'Alice');
      when(() => userBloc.state).thenReturn(_userState(users: [user]));

      await tester.pumpWidget(_wrap(page(memberIds: const {})));
      await tester.pump();

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('user list ẩn user đã là member', (tester) async {
      final user = _user(id: 'u1', displayName: 'Bob');
      when(() => userBloc.state).thenReturn(_userState(users: [user]));

      await tester.pumpWidget(_wrap(page(memberIds: {'u1'})));
      await tester.pump();

      expect(find.text('Bob'), findsNothing);
    });

    testWidgets(
        'user list ẩn user đã là member (kiểm tra qua currentMemberIds)',
        (tester) async {
      // isCurrentUser is always false in tests (no Firebase Auth).
      // Filtering current user is tested via currentMemberIds instead.
      final currentUser = _user(id: 'owner1', displayName: 'Owner');
      when(() => userBloc.state)
          .thenReturn(_userState(users: [currentUser]));

      // owner1 is in currentMemberIds → should be filtered out
      await tester.pumpWidget(_wrap(page(memberIds: {'owner1'})));
      await tester.pump();

      expect(find.text('Owner'), findsNothing);
    });

    testWidgets('tap user dispatch AddMember và pop', (tester) async {
      final user = _user(id: 'u2', displayName: 'Carol');
      when(() => userBloc.state).thenReturn(_userState(users: [user]));

      await tester.pumpWidget(_wrap(page()));
      await tester.pump();

      await tester.tap(find.text('Carol'));
      await tester.pump();

      verify(() => groupBloc.add(const AddMember('G1', 'u2'))).called(1);
    });
  });
}
