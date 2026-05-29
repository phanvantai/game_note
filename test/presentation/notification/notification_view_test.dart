import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/firebase/firestore/notification/gn_notification.dart';
import 'package:pes_arena/l10n/generated/app_localizations.dart';
import 'package:pes_arena/presentation/notification/bloc/notification_bloc.dart';
import 'package:pes_arena/presentation/notification/notification_view.dart';

class _MockNotificationBloc
    extends MockBloc<NotificationEvent, NotificationState>
    implements NotificationBloc {}

GNNotification _notification({
  required String id,
  required String title,
  bool isRead = false,
}) {
  return GNNotification(
    id: id,
    userId: 'user-id',
    title: title,
    message: 'Nội dung $title',
    type: GNNotificationType.unknown.value,
    timestamp: DateTime(2026, 5, 20, 10),
    isRead: isRead,
  );
}

Widget _wrap(NotificationBloc bloc) {
  return BlocProvider<NotificationBloc>.value(
    value: bloc,
    child: const MaterialApp(
      locale: Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: NotificationView(),
    ),
  );
}

void main() {
  testWidgets('hiển thị loading và empty state', (tester) async {
    final bloc = _MockNotificationBloc();
    when(
      () => bloc.state,
    ).thenReturn(const NotificationState(viewStatus: ViewStatus.loading));

    await tester.pumpWidget(_wrap(bloc));

    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(find.text('Chưa đọc'), findsOneWidget);
    expect(find.text('Tổng'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(2));
  });

  testWidgets('refresh dispatch fetch event', (tester) async {
    final bloc = _MockNotificationBloc();
    when(() => bloc.state).thenReturn(const NotificationState());

    await tester.pumpWidget(_wrap(bloc));

    final refresh = tester.widget<RefreshIndicator>(
      find.byType(RefreshIndicator),
    );
    await refresh.onRefresh();

    verify(() => bloc.add(NotificationEventFetch())).called(1);
  });

  testWidgets('hiển thị list, số chưa đọc và mark all action', (tester) async {
    final bloc = _MockNotificationBloc();
    when(() => bloc.state).thenReturn(
      NotificationState(
        viewStatus: ViewStatus.success,
        notifications: [
          _notification(id: 'n1', title: 'Thông báo chưa đọc'),
          _notification(id: 'n2', title: 'Thông báo đã đọc', isRead: true),
        ],
      ),
    );

    await tester.pumpWidget(_wrap(bloc));
    await tester.pump();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Thông báo chưa đọc'), findsOneWidget);
    expect(find.text('Thông báo đã đọc'), findsOneWidget);
    expect(find.text('1 thông báo mới'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.done_all_outlined));
    await tester.pump();

    verify(() => bloc.add(NotificationEventMarkAllAsRead())).called(1);
  });
}
