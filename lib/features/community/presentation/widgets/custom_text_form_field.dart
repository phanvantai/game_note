import 'package:flutter/material.dart';

class CustomTextFormField extends StatefulWidget {
  final String placeholder;
  final Color cursorColor;
  final bool isSecurity;
  final TextInputType textInputType;
  final void Function(String)? onChanged;
  const CustomTextFormField({
    Key? key,
    required this.placeholder,
    this.cursorColor = Colors.white,
    this.isSecurity = false,
    this.textInputType = TextInputType.text,
    this.onChanged,
  }) : super(key: key);

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late bool isSecurity;

  @override
  void initState() {
    super.initState();
    isSecurity = widget.isSecurity;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      obscureText: isSecurity,
      cursorColor: widget.cursorColor,
      decoration: InputDecoration(
        hintText: widget.placeholder,
        suffixIcon: widget.isSecurity
            ? IconButton(
                onPressed: () => setState(() {
                  isSecurity = !isSecurity;
                }),
                icon: Icon(
                  isSecurity ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
              )
            : null,
      ),
      keyboardType: widget.textInputType,
      autocorrect: false,
      onChanged: widget.onChanged,
    );
  }
}
