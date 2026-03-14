import 'package:flutter/material.dart';

import '../../routing.dart';

class OfflineButton extends StatelessWidget {
  const OfflineButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.wifi_off_outlined, size: 18),
      label: const Text('Offline'),
      onPressed: () {
        Navigator.of(context).pushReplacementNamed(Routing.offline);
      },
    );
  }
}
