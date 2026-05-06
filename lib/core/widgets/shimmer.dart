import 'package:flutter/material.dart';

/// Lightweight shimmer effect — animates a horizontal gradient sweep over
/// any child. Use [ShimmerBox] for the typical "rounded-rect placeholder"
/// case to avoid hand-rolling a Container each time.
///
/// Built in-house instead of pulling in `shimmer` because we only need
/// the basic sweep and that package adds ~50KB of code we don't use.
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration period;

  const Shimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 1400),
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.period)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.05),
      base,
    );
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // Slide a 3-stop linear gradient from off-screen left to right.
        final t = _controller.value;
        final dx = -1.5 + 3.0 * t; // -1.5 → +1.5 in unit-rect space
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(dx - 0.6, 0),
              end: Alignment(dx + 0.6, 0),
              colors: [base, highlight, base],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child!,
        );
      },
    );
  }
}

/// A solid rounded rectangle in the shimmer base color — pair with
/// [Shimmer] to render a placeholder block.
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius,
      ),
    );
  }
}
