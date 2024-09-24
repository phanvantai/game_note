import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        appBar: AppBar(title: const Text('Thông báo')),
        body: RefreshIndicator.adaptive(
          child: state.notifications.isEmpty
              ? const Center(
                  child: Text('Bạn không có thông báo nào'),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListView.separated(
                    itemBuilder: (context, index) => NotificationItem(
                      notification: state.notifications[index],
                    ),
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemCount: state.notifications.length,
                  ),
                ),
          onRefresh: () async {
            context.read<NotificationBloc>().add(NotificationEventFetch());
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
