import 'package:flutter/material.dart';

import 'sign_in/sign_in_page.dart';
import 'third_party/auth_buttons_view.dart';

class AuthView extends StatelessWidget {
  const AuthView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.9),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SignInPage(),
            const SizedBox(height: 48, width: double.maxFinite),
            Row(
              children: [
                const Spacer(),
                Expanded(
                  child: Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Hoặc', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 4),
                Expanded(
                  child: Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
              ],
            ),
            const AuthButtonsView(),
          ],
        ),
      ),
    );
  }
}
