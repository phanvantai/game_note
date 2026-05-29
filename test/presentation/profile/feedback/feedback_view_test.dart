import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/ultils.dart';
import 'package:pes_arena/firebase/auth/gn_auth.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/gn_collection.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/profile/feedback/feedback_view.dart';

class _MockFirebaseAuth extends Mock implements FirebaseAuth {}

class _MockGNAuth extends Mock implements GNAuth {}

class _MockFirebaseUser extends Mock implements User {}

void main() {
  late FakeFirebaseFirestore firestore;
  late _MockGNAuth auth;
  late _MockFirebaseAuth firebaseAuth;
  late _MockFirebaseUser user;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    auth = _MockGNAuth();
    firebaseAuth = _MockFirebaseAuth();
    user = _MockFirebaseUser();

    when(() => auth.auth).thenReturn(firebaseAuth);
    when(() => firebaseAuth.currentUser).thenReturn(null);

    when(() => auth.currentUser).thenReturn(user);

    getIt.registerSingleton<GNAuth>(auth);
    getIt.registerSingleton<GNFirestore>(GNFirestore(firestore));
    setShowToastImpl((_, {gravity = ToastGravity.BOTTOM}) {});
  });

  tearDown(() {
    resetShowToast();
    getIt.reset();
  });

  testWidgets('shows loading state while loading feedback list', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Chưa có góp ý nào'), findsOneWidget);
  });

  testWidgets('shows empty state when no feedback exists', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Chưa có góp ý nào'), findsOneWidget);
    expect(
      find.text('Nhấn nút + để thêm góp ý mới'),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('shows error state when feedback parsing fails', (tester) async {
    await firestore.collection(GNCollection.feedbacks).doc('broken').set(
      {'bad': 'data'},
    );

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Đã xảy ra lỗi'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('renders list state with hero and feedback item', (tester) async {
    await firestore.collection(GNCollection.feedbacks).doc('f1').set({
      'status': 0,
      'title': 'Góp ý giao diện',
      'detail': 'Chi tiết đề xuất dài hơn 10 ký tự.',
      'userId': 'u1',
      'createdAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'updatedAt': Timestamp.fromDate(DateTime(2026, 1, 1)),
    });

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Feedback board'), findsOneWidget);
    expect(find.text('Góp ý cộng đồng'), findsOneWidget);
    expect(find.text('Theo dõi và gửi phản hồi để cải thiện PES Arena.'), findsOneWidget);
    expect(find.text('Góp ý giao diện'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('shows signin required snackbar for unauthenticated user', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Bạn cần đăng nhập để gửi phản hồi.'), findsOneWidget);
    expect(find.text('Tạo phản hồi'), findsNothing);
  });

  testWidgets('validates required feedback fields', (tester) async {
    when(() => firebaseAuth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('u1');

    String? toastMessage;
    setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {
      toastMessage = message;
    });

    await tester.pumpWidget(_app());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Gửi'));
    await tester.pump();

    expect(toastMessage, 'Vui lòng điền đầy đủ thông tin.');
    expect(find.text('Tạo phản hồi'), findsOneWidget);
  });

  testWidgets('validates minimum length for feedback fields', (tester) async {
    when(() => firebaseAuth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('u1');
    String? toastMessage;
    setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {
      toastMessage = message;
    });

    await tester.pumpWidget(_app());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Bug');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Ngắn thôi',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi'));
    await tester.pump();

    expect(
      toastMessage,
      'Tiêu đề phải có ít nhất 5 ký tự\nNội dung phải có ít nhất 10 ký tự.',
    );
    expect(find.text('Tạo phản hồi'), findsOneWidget);
  });

  testWidgets('creates feedback successfully for authenticated user', (tester) async {
    when(() => firebaseAuth.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('u1');
    String? toastMessage;
    setShowToastImpl((message, {gravity = ToastGravity.BOTTOM}) {
      toastMessage = message;
    });

    await tester.pumpWidget(_app());
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Góp ý giao diện mới');
    await tester.enterText(
      find.byType(TextField).at(1),
      'Báo lỗi trong game mới xuất hiện khi mở bảng xếp hạng.',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi'));
    await tester.pumpAndSettle();

    final snapshot = await firestore
        .collection(GNCollection.feedbacks)
        .get();
    expect(snapshot.docs, hasLength(1));
    final data = snapshot.docs.first.data();

    expect(data['title'], 'Góp ý giao diện mới');
    expect(
      data['detail'],
      'Báo lỗi trong game mới xuất hiện khi mở bảng xếp hạng.',
    );
    expect(data['status'], 0);
    expect(data['userId'], 'u1');
    expect(toastMessage, 'Góp ý đã được gửi thành công!');
    expect(find.byType(AlertDialog), findsNothing);
  });
}

Widget _app() {
  return MaterialApp(
    home: const FeedbackView(),
  );
}
