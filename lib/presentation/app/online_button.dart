import 'package:flutter/material.dart';

import '../../routing.dart';

class OnlineButton extends StatelessWidget {
  const OnlineButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.wifi_outlined, size: 18),
      label: const Text('Online'),
      onPressed: () {
        Navigator.of(context).pushReplacementNamed(Routing.app);
      },
    );
  }
}
