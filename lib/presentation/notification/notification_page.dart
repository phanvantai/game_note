import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../injection_container.dart';
import 'bloc/notification_bloc.dart';
import 'notification_view.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use BlocProvider.value to reference the existing singleton instance
    // instead of creating a new one that would be disposed when popped
    return BlocProvider<NotificationBloc>.value(
      value: getIt<NotificationBloc>(),
      child: const NotificationView(),
    );
  }
}