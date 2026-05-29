import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/firebase/firestore/notification/gn_notification.dart';
import 'package:pes_arena/presentation/notification/bloc/notification_bloc.dart';
import 'package:pes_arena/presentation/notification/notification_item.dart';

class _MockNotificationBloc
    extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

void main() {
  Widget wrap(GNNotification notification) {
    return MaterialApp(
      home: Scaffold(body: NotificationItem(notification: notification)),
    );
  }

  Widget wrapWithBloc({
    required GNNotification notification,
    required NotificationBloc notificationBloc,
    bool useRouter = false,
  }) {
    final child = BlocProvider<NotificationBloc>.value(
      value: notificationBloc,
      child: Scaffold(body: NotificationItem(notification: notification)),
    );

    if (!useRouter) {
      return MaterialApp(home: child);
    }

    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (context, state) => child),
        GoRoute(
          path: '/tournament/:leagueId',
          builder: (context, state) => Scaffold(
            body: Text('detail-${state.pathParameters['leagueId']}'),
          ),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  bool isUnreadDotWidget(Widget widget) {
    return widget is Container &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).shape == BoxShape.circle;
  }

  Container itemContainer(WidgetTester tester) {
    final candidates = tester.widgetList<Container>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.padding == const EdgeInsets.all(14) &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color != null,
      ),
    );

    return candidates.first;
  }

  GNNotification notificationFixture({
    required String title,
    required String message,
    required DateTime timestamp,
    required bool isRead,
    required String type,
    String? relatedId,
  }) {
    return GNNotification(
      id: 'notification-id',
      userId: 'user-id',
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: isRead,
      relatedId: relatedId,
    );
  }

  testWidgets('renders unread notification with unread styling and indicator', (
    tester,
  ) async {
    final notification = notificationFixture(
      title: 'Chào mừng',
      message: 'Bạn có một thông báo mới.',
      timestamp: DateTime(2026, 5, 1, 9, 5),
      isRead: false,
      type: GNNotificationType.esportsLeague.value,
      relatedId: 'league-1',
    );

    await tester.pumpWidget(wrap(notification));
    await tester.pump();

    expect(find.text(notification.title), findsOneWidget);
    expect(find.text(notification.message), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            widget.data!.contains('01/05') &&
            widget.data!.contains('09:05'),
      ),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.notifications_active_outlined), findsNothing);
    expect(
      find.byWidgetPredicate((widget) => isUnreadDotWidget(widget)),
      findsOneWidget,
    );
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.text('Giải đấu'), findsOneWidget);

    final titleStyle =
        tester.widget<Text>(find.text(notification.title)).style ??
        const TextStyle();
    expect(titleStyle.fontWeight, FontWeight.w800);

    final context = tester.element(find.text(notification.title));
    final theme = Theme.of(context).colorScheme;
    final expectedBackground = Color.alphaBlend(
      theme.onSurface.withValues(alpha: 0.04),
      theme.surfaceContainerHighest,
    );
    final actualBackground =
        (itemContainer(tester).decoration as BoxDecoration).color;
    expect(actualBackground, expectedBackground);

    final chipText = tester.widget<Text>(find.text('Giải đấu'));
    final expectedChipTextColor = theme.onSurface;
    expect(chipText.style?.color, expectedChipTextColor);
  });

  testWidgets(
    'renders read notification without unread indicator and uses read style',
    (tester) async {
      final notification = notificationFixture(
        title: 'Đã đọc',
        message: 'Nội dung thông báo này đã được đọc.',
        timestamp: DateTime(2026, 5, 1, 10, 30),
        isRead: true,
        type: GNNotificationType.unknown.value,
      );

      await tester.pumpWidget(wrap(notification));
      await tester.pump();

      expect(
        find.byWidgetPredicate((widget) => isUnreadDotWidget(widget)),
        findsNothing,
      );
      expect(find.byIcon(Icons.notifications), findsOneWidget);

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              widget.data != null &&
              widget.data!.contains('01/05') &&
              widget.data!.contains('10:30'),
        ),
        findsOneWidget,
      );

      final titleStyle =
          tester.widget<Text>(find.text(notification.title)).style ??
          const TextStyle();
      expect(titleStyle.fontWeight, FontWeight.w600);

      final context = tester.element(find.text(notification.title));
      final theme = Theme.of(context).colorScheme;
      final expectedBackground = theme.surfaceContainerHighest;
      final actualBackground =
          (itemContainer(tester).decoration as BoxDecoration).color;
      expect(actualBackground, expectedBackground);
    },
  );

  testWidgets('does not render related chip without relatedId', (tester) async {
    final notification = notificationFixture(
      title: 'Không có liên kết',
      message: 'Không có chip nhóm/giải đấu.',
      timestamp: DateTime(2026, 5, 1, 11, 0),
      isRead: true,
      type: GNNotificationType.unknown.value,
    );

    await tester.pumpWidget(wrap(notification));
    await tester.pump();

    expect(find.text('Thông báo'), findsNothing);
  });

  testWidgets('renders dotless icon when notification type is unknown', (
    tester,
  ) async {
    final notification = notificationFixture(
      title: 'Thông báo hệ thống',
      message: 'Đây là loại thông báo mặc định.',
      timestamp: DateTime(2026, 5, 1, 11, 45),
      isRead: false,
      type: GNNotificationType.unknown.value,
      relatedId: null,
    );

    await tester.pumpWidget(wrap(notification));
    await tester.pump();

    expect(find.byIcon(Icons.notifications), findsOneWidget);
  });

  testWidgets(
    'tapping unread league notification dispatches mark-as-read and navigates',
    (tester) async {
      final notification = notificationFixture(
        title: 'Đi tới giải đấu',
        message: 'Nhận thông báo giải đấu mới.',
        timestamp: DateTime(2026, 5, 1, 11, 45),
        isRead: false,
        type: GNNotificationType.esportsLeague.value,
        relatedId: 'league-77',
      );
      final bloc = _MockNotificationBloc();

      await tester.pumpWidget(
        wrapWithBloc(
          notification: notification,
          notificationBloc: bloc,
          useRouter: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(notification.title));
      await tester.pumpAndSettle();

      verify(
        () => bloc.add(NotificationEventMarkAsRead(notification.id)),
      ).called(1);
      expect(find.text('detail-league-77'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping read league notification does not dispatch mark-as-read and still navigates',
    (tester) async {
      final notification = notificationFixture(
        title: 'Giải đấu đã đọc',
        message: 'Không cần đánh dấu lại là đọc.',
        timestamp: DateTime(2026, 5, 1, 8, 22),
        isRead: true,
        type: GNNotificationType.esportsLeague.value,
        relatedId: 'league-88',
      );
      final bloc = _MockNotificationBloc();

      await tester.pumpWidget(
        wrapWithBloc(
          notification: notification,
          notificationBloc: bloc,
          useRouter: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(notification.title));
      await tester.pumpAndSettle();

      verifyNever(() => bloc.add(NotificationEventMarkAsRead(notification.id)));
      expect(find.text('detail-league-88'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping unread non-league notification only marks as read without navigating',
    (tester) async {
      final notification = notificationFixture(
        title: 'Nhóm mới',
        message: 'Thông báo nhóm mới không liên quan giải đấu.',
        timestamp: DateTime(2026, 5, 1, 9, 0),
        isRead: false,
        type: GNNotificationType.esportsGroup.value,
        relatedId: 'group-44',
      );
      final bloc = _MockNotificationBloc();

      await tester.pumpWidget(
        wrapWithBloc(
          notification: notification,
          notificationBloc: bloc,
          useRouter: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(notification.title));
      await tester.pumpAndSettle();

      verify(
        () => bloc.add(NotificationEventMarkAsRead(notification.id)),
      ).called(1);
      expect(find.text('detail-group-44'), findsNothing);
      expect(find.text('detail-league-88'), findsNothing);
    },
  );

  testWidgets('delete action dispatches delete event', (tester) async {
    final notification = notificationFixture(
      title: 'Xóa thông báo',
      message: 'Vuốt để xóa thông báo.',
      timestamp: DateTime(2026, 5, 1, 7, 15),
      isRead: true,
      type: GNNotificationType.unknown.value,
      relatedId: null,
    );
    final bloc = _MockNotificationBloc();

    await tester.pumpWidget(
      wrapWithBloc(notification: notification, notificationBloc: bloc),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(NotificationItem), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    verify(() => bloc.add(NotificationEventDelete(notification.id))).called(1);
  });

  testWidgets('renders chip for unknown related notification type', (
    tester,
  ) async {
    final notification = notificationFixture(
      title: 'Thông báo liên kết',
      message: 'Có một loại thông báo mặc định.',
      timestamp: DateTime(2026, 5, 1, 13, 30),
      isRead: true,
      type: GNNotificationType.unknown.value,
      relatedId: 'something-1',
    );

    await tester.pumpWidget(wrap(notification));
    await tester.pump();

    expect(find.text('Thông báo'), findsOneWidget);

    final chip = tester.widget<Text>(find.text('Thông báo'));
    final context = tester.element(find.text('Thông báo'));
    final theme = Theme.of(context).colorScheme;
    expect(chip.style?.color, theme.onSurfaceVariant);
  });
}
