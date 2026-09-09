import 'package:deliveryboy/commons/widgets/app_text.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/string_extensions.dart';
import 'package:flutter/material.dart';

class BillRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDiscount;
  final String? suffixLabel;
  const BillRow({
    super.key,
    required this.label,
    required this.value,
    this.isDiscount = false,
    this.suffixLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDiscount
        ? context.cs.onSecondaryContainer
        : context.cs.onSurfaceVariant;
    return Row(
      mainAxisAlignment: .spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: .min,
            children: [
              AppText(
                label,
                style: context.tt.labelMedium?.copyWith(color: color),
              ),
              if (suffixLabel.isNotNullOrEmpty) ...[
                AppSpacing.w4,
                Flexible(
                  child: AppText(
                    suffixLabel!,
                    style: context.tt.labelSmall?.copyWith(
                      color: context.cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    overflow: .ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        AppText(
          value,
          style: context.tt.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
