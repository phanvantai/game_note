import 'package:flutter/material.dart';

class MenuItemView extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final VoidCallback? callback;
  const MenuItemView({
    Key? key,
    required this.title,
    this.trailing,
    this.callback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: callback,
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Row(
          children: [
            const SizedBox(width: 24),
            Text(title),
            const Spacer(),
            //trailing,
            const SizedBox(width: 24),
          ],
        ),
      ),
    );
  }
}
