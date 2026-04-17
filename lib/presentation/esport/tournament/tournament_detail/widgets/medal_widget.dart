import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class MedalWidget extends StatelessWidget {
  final Color? color;
  final double? size;
  const MedalWidget({super.key, this.color, this.size});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/svg/medal-solid.svg',
      width: size ?? 24,
      height: size ?? 24,
      colorFilter: ColorFilter.mode(
        color ?? Theme.of(context).colorScheme.onSurface,
        BlendMode.srcIn,
      ),
    );
  }
}
