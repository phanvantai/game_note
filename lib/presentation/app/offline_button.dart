import 'package:flutter/material.dart';

import '../../routing.dart';

class OfflineButton extends StatelessWidget {
  const OfflineButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.signal_wifi_off_sharp),
      label: const Text("Chế độ Offline"),
      onPressed: () {
        Navigator.of(context).pushReplacementNamed(Routing.offline);
      },
    );
  }
}
