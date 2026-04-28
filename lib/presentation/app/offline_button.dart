import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing.dart';

class OfflineButton extends StatelessWidget {
  const OfflineButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.wifi_off_outlined, size: 18),
      label: const Text('Offline'),
      onPressed: () {
        context.go(Routing.offline);
      },
    );
  }
}
