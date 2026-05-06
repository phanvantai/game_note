import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing.dart';

class OnlineButton extends StatelessWidget {
  const OnlineButton({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.wifi_outlined, size: 18),
      label: const Text('Online'),
      onPressed: () {
        context.go(Routing.app);
      },
    );
  }
}
