import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pes_arena/core/theme/app_colors.dart';
import 'package:pes_arena/firebase/firestore/feedback/feedback_model.dart';
import 'package:pes_arena/firebase/firestore/gn_firestore.dart';
import 'package:pes_arena/firebase/firestore/user/gn_user.dart';
import 'package:pes_arena/injection_container.dart';
import 'package:pes_arena/presentation/profile/feedback/feedback_item.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    getIt.registerSingleton<GNFirestore>(GNFirestore(firestore));
  });

  tearDown(() => getIt.reset());

  testWidgets('renders fallback avatar when user has no photo', (tester) async {
    await _createUser('u1', photoUrl: null);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FeedbackItem(feedback: _feedback())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bug'), findsOneWidget);
    expect(find.text('Chưa tiếp nhận'), findsOneWidget);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('renders network avatar when user has photo', (tester) async {
    await _createUser('u1', photoUrl: 'https://example.com/a.png');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FeedbackItem(feedback: _feedback())),
      ),
    );
    await tester.pumpAndSettle();
    while (tester.takeException() != null) {}

    final avatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar).last);
    expect(avatar.backgroundImage, isA<NetworkImage>());
  });

  testWidgets('renders processing status with warning color', (tester) async {
    await _createUser('u1', photoUrl: null);
    await _pumpFeedbackItem(tester, status: 1);

    final statusText = tester.widget<Text>(find.text('Đang xử lý'));
    expect(statusText.style?.color, equals(AppColors.lightWarning));
    expect(find.text('Đang xử lý'), findsOneWidget);
  });

  testWidgets('renders done status with success color', (tester) async {
    await _createUser('u1', photoUrl: null);
    await _pumpFeedbackItem(tester, status: 2);

    final statusText = tester.widget<Text>(find.text('Đã xử lý'));
    expect(statusText.style?.color, equals(AppColors.lightSuccess));
    expect(find.text('Đã xử lý'), findsOneWidget);
  });

  testWidgets('renders rejected status with error color', (tester) async {
    await _createUser('u1', photoUrl: null);
    await _pumpFeedbackItem(tester, status: 3);

    final statusText = tester.widget<Text>(find.text('Không xử lý'));
    expect(statusText.style?.color, equals(AppColors.lightError));
    expect(find.text('Không xử lý'), findsOneWidget);
  });
}

Future<void> _createUser(String id, {required String? photoUrl}) async {
  await getIt<GNFirestore>().firestore
      .collection(GNUser.collectionName)
      .doc(id)
      .set({
        GNUser.displayNameKey: 'Tai',
        GNUser.phoneNumberKey: null,
        GNUser.emailKey: null,
        GNUser.photoUrlKey: photoUrl,
        GNUser.roleKey: 'user',
        GNUser.fcmTokenKey: '',
      });
}

Future<void> _pumpFeedbackItem(
  WidgetTester tester, {
  required int status,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(
        colorScheme: AppColors.lightColorScheme,
        useMaterial3: true,
      ),
      home: Scaffold(body: FeedbackItem(feedback: _feedback(status))),
    ),
  );
  await tester.pumpAndSettle();
}

FeedbackModel _feedback([int status = 0]) {
  final now = DateTime(2026, 5, 10);
  return FeedbackModel(
    id: 'F1',
    status: status,
    title: 'Bug',
    detail: 'Details',
    userId: 'u1',
    createdAt: now,
    updatedAt: now,
  );
}
