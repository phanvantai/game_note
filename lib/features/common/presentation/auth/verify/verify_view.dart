import 'package:flutter/material.dart';
import 'package:game_note/firebase/auth/gn_auth.dart';

import '../../../../../injection_container.dart';

class VerifyView extends StatelessWidget {
  VerifyView({Key? key}) : super(key: key);

  final TextEditingController _codeController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.9),
      appBar: AppBar(
        title: const Text('Đăng nhập'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: double.maxFinite, height: 64),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.white70,
              ),
              padding: EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text(
                    'Xác thực tài khoản',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Mã xác thực đã được gửi đến số điện thoại của bạn',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Mã xác thực',
                    ),
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // TODO: Verify code
                      print(_codeController.text);
                      try {
                        final result = await getIt<GNAuth>()
                            .signInWithPhoneNumber(_codeController.text);
                        print(result);
                        Navigator.of(context).pop(true);
                      } catch (e) {
                        print(e);
                      }
                    },
                    child: const Text('Xác thực'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Resend code
                    },
                    child: const Text('Gửi lại mã xác thực'),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
