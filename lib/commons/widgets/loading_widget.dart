import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Centered circular progress indicator sized for inline use.
class LoadingWidget extends StatelessWidget {
  final double size;
  final Color? color;

  const LoadingWidget({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: color ?? context.cs.primary,
        ),
      ),
    );
  }
}
