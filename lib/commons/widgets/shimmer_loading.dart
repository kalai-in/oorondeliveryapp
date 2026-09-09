import 'package:flutter/material.dart';
import 'package:deliveryboy/core/theme/app_decorations.dart';
import '../../core/theme/app_radius.dart';
import '../../utils/extensions/context_extensions.dart';

/// Wraps [child] in an animated shimmer sweep, used for skeleton loading placeholders.
class ShimmerLoading extends StatefulWidget {
  final Widget child;

  const ShimmerLoading({super.key, required this.child});

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.cs.onSurface.withValues(alpha: 0.06);
    final highlight = context.cs.onSurface.withValues(alpha: 0.14);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = _controller.value * 3 - 1;
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              begin: AlignmentDirectional(-1 + dx, 0),
              end: AlignmentDirectional(1 + dx, 0),
            ).createShader(bounds, textDirection: Directionality.of(context));
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Two equal-width [ShimmerBox]es side by side — the stat-tile rows that
/// repeat across the dashboard and earnings skeletons.
class ShimmerCardRow extends StatelessWidget {
  final double height;
  final double spacing;
  final BorderRadius borderRadius;

  const ShimmerCardRow({
    super.key,
    required this.height,
    this.spacing = 16,
    this.borderRadius = AppRadius.r16,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: spacing,
      children: [
        Expanded(
          child: ShimmerBox(height: height, borderRadius: borderRadius),
        ),
        Expanded(
          child: ShimmerBox(height: height, borderRadius: borderRadius),
        ),
      ],
    );
  }
}

/// Solid rounded-rectangle placeholder block used inside a [ShimmerLoading].
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = AppRadius.r14,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: AppDecorations.card(
        color: context.cs.onSurface.withValues(alpha: 0.08),
        borderRadius: borderRadius,
      ),
    );
  }
}
