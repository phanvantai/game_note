import 'package:flutter/material.dart';

class CreateAccountView extends StatelessWidget {
  const CreateAccountView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: const [
          Text('create account'),
          TextField(),
          TextField(),
          TextField(),
        ],
      ),
    );
  }
}
