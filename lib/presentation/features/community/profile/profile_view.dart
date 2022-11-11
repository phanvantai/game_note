import 'package:flutter/material.dart';
import 'package:game_note/presentation/app/switch_mode_widget.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: const [
            SwitchModeWidget(),
          ],
        ),
      ),
    );
  }
}
