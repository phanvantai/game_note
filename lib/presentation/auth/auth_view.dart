import 'package:flutter/material.dart';
import 'package:pes_arena/presentation/app/offline_button.dart';

import 'sign_in/sign_in_page.dart';
import 'third_party/auth_buttons_view.dart';

class AuthView extends StatelessWidget {
  const AuthView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: const [OfflineButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100, width: double.maxFinite),
              const SignInPage(),
              const SizedBox(height: 48, width: double.maxFinite),
              Row(
                children: [
                  const Spacer(),
                  Expanded(
                    child: Container(
                      height: 1,
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('Hoặc', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Container(
                      height: 1,
                      width: double.infinity,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
              const AuthButtonsView(),
            ],
          ),
        ),
      ),
    );
  }
}
