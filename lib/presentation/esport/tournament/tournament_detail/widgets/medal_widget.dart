import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MedalWidget extends StatelessWidget {
  final Color? color;
  final double? size;
  const MedalWidget({Key? key, this.color, this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/medal-solid.svg',
      width: size ?? 24,
      height: size ?? 24,
      colorFilter: ColorFilter.mode(color ?? Colors.black, BlendMode.srcIn),
    );
  }
}
