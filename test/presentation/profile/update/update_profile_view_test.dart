import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/profile/update/bloc/update_profile_bloc.dart';
import 'package:pes_arena/presentation/profile/update/update_profile_view.dart';
import 'package:pes_arena/routing.dart';

class _MockUpdateProfileBloc
    extends MockBloc<UpdateProfileEvent, UpdateProfileState>
    implements UpdateProfileBloc {}

Widget _materialApp({
  required UpdateProfileBloc bloc,
  required UpdateProfileState initialState,
  Stream<UpdateProfileState>? stateStream,
}) {
  when(() => bloc.state).thenReturn(initialState);
  whenListen(
    bloc,
    stateStream ?? Stream<UpdateProfileState>.empty(),
    initialState: initialState,
  );

  return MaterialApp(
    locale: const Locale('vi'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: BlocProvider<UpdateProfileBloc>.value(
      value: bloc,
      child: const UpdateProfileView(),
    ),
  );
}

Widget _routerApp({
  required UpdateProfileBloc bloc,
  required UpdateProfileState initialState,
  required Stream<UpdateProfileState> stateStream,
}) {
  when(() => bloc.state).thenReturn(initialState);
  whenListen(bloc, stateStream, initialState: initialState);

  final router = GoRouter(
    initialLocation: Routing.updateProfile,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('HOME_SCREEN'))),
      ),
      GoRoute(
        path: Routing.updateProfile,
        builder: (_, _) => BlocProvider<UpdateProfileBloc>.value(
          value: bloc,
          child: const UpdateProfileView(),
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

UpdateProfileState _state({
  ViewStatus viewStatus = ViewStatus.initial,
  GNUser? user,
  String error = '',
}) {
  return UpdateProfileState(viewStatus: viewStatus, user: user, error: error);
}

GNUser _user({
  required String id,
  required String displayName,
  required String phoneNumber,
  required String email,
}) {
  return GNUser(
    id: id,
    displayName: displayName,
    phoneNumber: phoneNumber,
    email: email,
    photoUrl: null,
    role: 'user',
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const SubmittUpdateProfile(
        userDisplayName: '',
        userPhoneNumber: '',
        userEmail: '',
      ),
    );
  });

  setUp(() {
    setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {});
  });

  tearDown(() {
    resetShowToast();
  });

  final initialUser = _user(
    id: 'u1',
    displayName: 'Nguyen Van A',
    phoneNumber: '0909000111',
    email: 'van.a@example.com',
  );

  testWidgets('prefills form fields with initial user values', (tester) async {
    final bloc = _MockUpdateProfileBloc();

    await tester.pumpWidget(
      _materialApp(
        bloc: bloc,
        initialState: _state(user: initialUser),
      ),
    );

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .toList();
    expect(fields, hasLength(3));
    expect(fields[0].controller!.text, initialUser.displayName);
    expect(fields[1].controller!.text, initialUser.phoneNumber);
    expect(fields[2].controller!.text, initialUser.email);
  });

  testWidgets('renders hero and form fields', (tester) async {
    final bloc = _MockUpdateProfileBloc();

    await tester.pumpWidget(
      _materialApp(
        bloc: bloc,
        initialState: _state(user: initialUser),
      ),
    );

    expect(find.text('Profile setup'), findsOneWidget);
    expect(find.text('Thông tin hiển thị'), findsOneWidget);
    expect(find.text('Cập nhật tên, số điện thoại và email.'), findsOneWidget);
    expect(find.text('Họ và tên'), findsOneWidget);
    expect(find.text('Số điện thoại'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Cập nhật'), findsOneWidget);
  });

  testWidgets(
    'shows loading indicator and disables submit button while loading',
    (tester) async {
      final bloc = _MockUpdateProfileBloc();

      await tester.pumpWidget(
        _materialApp(
          bloc: bloc,
          initialState: _state(
            user: initialUser,
            viewStatus: ViewStatus.loading,
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Cập nhật'),
      );
      expect(button.onPressed, isNull);
    },
  );

  testWidgets('dispatches submit event with form values when button pressed', (
    tester,
  ) async {
    final bloc = _MockUpdateProfileBloc();
    final expectedEvent = const SubmittUpdateProfile(
      userDisplayName: 'Tran Van B',
      userPhoneNumber: '0988777444',
      userEmail: 'van.b@example.com',
    );

    await tester.pumpWidget(
      _materialApp(
        bloc: bloc,
        initialState: _state(user: initialUser),
      ),
    );

    await tester.enterText(
      find.byType(TextField).at(0),
      expectedEvent.userDisplayName,
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      expectedEvent.userPhoneNumber,
    );
    await tester.enterText(
      find.byType(TextField).at(2),
      expectedEvent.userEmail,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Cập nhật'));
    await tester.pump();

    verify(() => bloc.add(expectedEvent)).called(1);
  });

  testWidgets('shows toast when bloc emits an error state', (tester) async {
    final bloc = _MockUpdateProfileBloc();
    const errorMessage = 'Không thể cập nhật thông tin';
    var capturedToast = '';

    setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {
      capturedToast = message;
    });

    await tester.pumpWidget(
      _materialApp(
        bloc: bloc,
        initialState: _state(user: initialUser),
        stateStream: Stream.value(
          _state(
            user: initialUser,
            viewStatus: ViewStatus.failure,
            error: errorMessage,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(capturedToast, errorMessage);
  });

  testWidgets('navigates back and shows toast when update succeeds', (
    tester,
  ) async {
    final bloc = _MockUpdateProfileBloc();
    var capturedToast = '';

    setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {
      capturedToast = message;
    });

    await tester.pumpWidget(
      _routerApp(
        bloc: bloc,
        initialState: _state(user: initialUser),
        stateStream: Stream.value(
          _state(user: initialUser, viewStatus: ViewStatus.success),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('HOME_SCREEN'), findsOneWidget);
    expect(capturedToast, 'Cập nhật thông tin thành công');
    expect(find.byType(UpdateProfileView), findsNothing);
  });
}
