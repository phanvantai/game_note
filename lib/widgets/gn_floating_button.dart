import 'package:flutter/material.dart';

class GNFloatingButton extends StatelessWidget {
  final void Function()? onPressed;
  final String label;
  final IconData? icon;
  const GNFloatingButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      label: Text(label),
      icon: Icon(icon ?? Icons.add),
      style: ButtonStyle(
        elevation: WidgetStateProperty.all(0),
        backgroundColor: WidgetStateProperty.all(Colors.red[100]),
      ),
    );
  }
}
