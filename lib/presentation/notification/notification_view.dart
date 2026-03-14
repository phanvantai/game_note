import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pes_arena/core/common/view_status.dart';
import 'package:pes_arena/core/widgets/app_ui_helpers.dart';

import 'bloc/notification_bloc.dart';
import 'notification_item.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({Key? key}) : super(key: key);

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          title: const Text('Thông báo'),
          actions: [
            IconButton(
              onPressed: () {
                context
                    .read<NotificationBloc>()
                    .add(NotificationEventMarkAllAsRead());
              },
              icon: const Icon(Icons.checklist_outlined),
              tooltip: 'Đánh dấu tất cả đã đọc',
            ),
          ],
        ),
        body: Column(
          children: [
            if (state.viewStatus == ViewStatus.loading)
              const LinearProgressIndicator(),
            Expanded(
              child: RefreshIndicator.adaptive(
                child: state.notifications.isEmpty
                    ? const AppEmptyState(
                        icon: Icons.notifications_none_outlined,
                        title: 'Không có thông báo nào',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) => NotificationItem(
                          notification: state.notifications[index],
                        ),
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemCount: state.notifications.length,
                      ),
                onRefresh: () async {
                  context
                      .read<NotificationBloc>()
                      .add(NotificationEventFetch());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
