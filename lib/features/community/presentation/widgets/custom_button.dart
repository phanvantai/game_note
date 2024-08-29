import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String? buttonText;
  final TextStyle? textStyle;
  final double? width;
  final double height;
  //final List<Color> gradientColor;
  final Color backgroundColor;
  final double? borderRadius;
  final VoidCallback? onPressed;
  final Widget? child;
  final double paddingHorizontal;
  final double paddingVertical;

  const CustomButton({
    Key? key,
    this.buttonText,
    required this.onPressed,
    this.width, // = double.maxFinite,
    this.height = 44,
    //this.gradientColor = kPrimaryGradient,
    this.borderRadius,
    this.textStyle,
    this.child,
    this.backgroundColor = Colors.orange,
    this.paddingHorizontal = 0,
    this.paddingVertical = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: paddingVertical,
      ),
      width: width,
      height: height,
      decoration: BoxDecoration(
        // gradient: LinearGradient(
        //   begin: Alignment.centerLeft,
        //   end: Alignment.centerRight,
        //   colors: gradientColor,
        // ),
        borderRadius: BorderRadius.circular(borderRadius ?? height / 2),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          shape: WidgetStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius ?? height / 2),
              //side: BorderSide(color: Colors.red),
            ),
          ),
          backgroundColor: WidgetStateProperty.all(backgroundColor),
          // elevation: MaterialStateProperty.all(3),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
        ),
        child: Container(
          // min sizes for Material buttons
          alignment: Alignment.center,
          child: child ??
              Text(
                buttonText ?? '',
                style: textStyle ??
                    const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
              ),
        ),
      ),
    );
  }
}
