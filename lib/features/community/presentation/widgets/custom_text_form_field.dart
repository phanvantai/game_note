import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final String placeholder;
  final Color cursorColor;
  final bool isSecurity;
  final TextInputType textInputType;
  const CustomTextFormField({
    Key? key,
    required this.placeholder,
    this.cursorColor = Colors.white,
    this.isSecurity = false,
    this.textInputType = TextInputType.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: isSecurity,
      cursorColor: cursorColor,
      decoration: InputDecoration(
        hintText: placeholder,
      ),
      keyboardType: textInputType,
    );
  }
}
