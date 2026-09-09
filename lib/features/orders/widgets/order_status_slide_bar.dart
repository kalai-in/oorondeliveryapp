import 'package:deliveryboy/commons/widgets/slide_to_confirm_button.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/size_extensions.dart';
import 'package:flutter/material.dart';

/// Shared bottom slide-to-confirm bar used by the quick-order, ecommerce and
/// return-request "advance to next status" actions. Purely presentational —
/// callers own their own cubits/models and only pass down primitives.
class OrderStatusSlideBar extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onConfirm;

  const OrderStatusSlideBar({
    super.key,
    required this.label,
    required this.isLoading,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPad = context.bottomSafePadding;
    return ColoredBox(
      color: context.cs.surface,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(
          ThemeConstants.paddingL,
          ThemeConstants.paddingM,
          ThemeConstants.paddingL,
          bottomPad + 12,
        ),
        child: SlideToConfirmButton(
          label: label,
          isLoading: isLoading,
          onConfirm: onConfirm,
        ),
      ),
    );
  }
}
