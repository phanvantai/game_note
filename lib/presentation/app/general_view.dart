import 'package:flutter/material.dart';
import 'package:game_note/core/constants/assets_path.dart';
import 'package:game_note/presentation/app/home_view.dart';
import 'package:game_note/presentation/widgets/custom_button.dart';

class GeneralView extends StatelessWidget {
  const GeneralView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            Image.asset(
              AssetsPath.appIcon,
              color: Colors.white,
              width: MediaQuery.of(context).size.width / 3,
            ),
            const SizedBox(height: 48, width: double.maxFinite),
            const Text(
              'Game Note',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            ),
            const SizedBox(height: 48, width: double.maxFinite),
            CustomButton(
              paddingHorizontal: 32,
              buttonText: 'Offline mode',
              backgroundColor: Colors.cyan,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HomeView(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            CustomButton(
              paddingHorizontal: 32,
              buttonText: 'Community mode',
              onPressed: () {
                print('community mode');
              },
            ),
            const Spacer(),
            const Spacer(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
