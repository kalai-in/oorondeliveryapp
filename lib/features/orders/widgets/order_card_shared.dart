import 'package:deliveryboy/commons/widgets/app_text.dart';
import 'package:deliveryboy/commons/widgets/status_chip.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/features/orders/utils/payment_breakdown.dart';
import 'package:deliveryboy/features/orders/widgets/payment_summary_section.dart';
import 'package:deliveryboy/utils/app_date_formatter.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:flutter/material.dart';

/// Header row shared by [OrderCard]/[EcommerceOrderCard]: order number + date
/// on the left, status chip on the right.
class OrderCardHeader extends StatelessWidget {
  final String orderNumber;
  final dynamic date;
  final String? activeStatus;
  final String? orderStatusName;

  const OrderCardHeader({
    super.key,
    required this.orderNumber,
    required this.date,
    required this.activeStatus,
    required this.orderStatusName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: .spaceBetween,
      crossAxisAlignment: .start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              AppText(orderNumber, style: context.tt.displayMedium),
              AppSpacing.h2,
              AppText(
                AppDateFormatter.formatDateTime(date),
                style: context.tt.labelSmall?.copyWith(
                  color: context.cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: .ellipsis,
              ),
            ],
          ),
        ),
        AppSpacing.w8,
        StatusChip.fromDynamicStatus(
          context,
          activeStatus,
          orderStatusName: orderStatusName,
        ),
      ],
    );
  }
}

/// Payment-label + combined-total footer row shared by [OrderCard] and
/// [EcommerceOrderCard], plus the optional "collect from customer" callout.
class OrderCardFooter extends StatelessWidget {
  final PaymentBreakdown breakdown;
  final String symbol;

  const OrderCardFooter({
    super.key,
    required this.breakdown,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Row(
          mainAxisAlignment: .spaceBetween,
          children: [
            Expanded(
              child: AppText(
                breakdown.combinedTotalLabel(context),
                style: context.tt.bodySmall?.copyWith(
                  color: context.cs.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: .ellipsis,
              ),
            ),
            AppSpacing.w8,
            AppText(
              '$symbol${breakdown.combinedTotalAmount.toStringAsFixed(0)}',
              style: context.tt.displayMedium?.copyWith(
                color: context.cs.onSurface,
              ),
            ),
          ],
        ),
        if (breakdown.mustCollectCash) ...[
          AppSpacing.h10,
          CollectFromCustomerCallout(breakdown: breakdown, symbol: symbol),
        ],
      ],
    );
  }
}
