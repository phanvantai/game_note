import 'package:flutter/material.dart';

import '../../routing.dart';

class OnlineButton extends StatelessWidget {
  const OnlineButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.signal_wifi_4_bar),
      label: const Text("Chế độ Online"),
      onPressed: () {
        Navigator.of(context).pushReplacementNamed(Routing.app);
      },
    );
  }
}
