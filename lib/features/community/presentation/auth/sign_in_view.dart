import 'package:flutter/material.dart';

class SignInView extends StatelessWidget {
  const SignInView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Text('signin'),
        TextField(),
        TextField(),
      ],
    );
  }
}
