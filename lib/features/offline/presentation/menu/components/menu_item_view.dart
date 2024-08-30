import 'package:flutter/material.dart';

class MenuItemView extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? callback;
  final Widget icon;
  const MenuItemView({
    Key? key,
    required this.title,
    required this.icon,
    this.trailing,
    this.callback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: callback,
      child: Container(
        //color: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const SizedBox(width: 12, height: 48),
            icon,
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const Spacer(),
            trailing ?? const SizedBox.shrink(),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
