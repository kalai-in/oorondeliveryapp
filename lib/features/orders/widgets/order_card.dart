import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/theme/app_decorations.dart';
import 'package:deliveryboy/features/orders/utils/payment_breakdown.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/variant_attributes_formatter.dart';
import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/order_status.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/commons/widgets/app_text.dart';
import 'order_card_shared.dart';

class OrderCard extends StatelessWidget {
  final OrderData order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final symbol = order.currency ?? "";
    final dividerColor = context.cs.outlineVariant;
    final items = order.items ?? [];
    final displayItems = items.take(2).toList();
    final extraCount = items.length - displayItems.length;
    final breakdown = PaymentBreakdown.compute(
      walletAmount: order.walletBalance,
      remainingAmount: order.finalTotal,
      paymentMethod: order.paymentMethod,
      isDelivered: order.activeStatus == OrderStatus.delivered.id,
      refundAmount: order.refundAmount,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsetsDirectional.only(bottom: ThemeConstants.paddingM),
        padding: const EdgeInsetsDirectional.all(ThemeConstants.paddingL),
        decoration: AppDecorations.shadowedCard(
          color: Theme.of(context).cardColor,
          shadowColor: context.cs.shadow,
        ),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            OrderCardHeader(
              orderNumber: '${order.orderNumber ?? order.id}',
              date: order.date!,
              activeStatus: order.activeStatus?.toString(),
              orderStatusName: order.orderStatusName,
            ),

            Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 10),
              child: Divider(height: 1, color: dividerColor),
            ),

            // ── Items ──
            if (displayItems.isNotEmpty) ...[
              AppSpacing.h10,
              ...displayItems.map(
                (item) => _ItemRow(item: item, currency: symbol),
              ),
              if (extraCount > 0)
                Padding(
                  padding: const EdgeInsetsDirectional.only(top: ThemeConstants.paddingXS),
                  child: AppText(
                    '+$extraCount more item${extraCount > 1 ? 's' : ''}',
                    style: context.tt.bodySmall?.copyWith(
                      color: context.cs.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],

            Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 10),
              child: Divider(height: 1, color: dividerColor),
            ),

            OrderCardFooter(breakdown: breakdown, symbol: symbol),
          ],
        ),
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItems item;
  final String? currency;
  const _ItemRow({required this.item, this.currency});

  @override
  Widget build(BuildContext context) {
    final name = item.productName ?? '';
    final variant = formatVariantPairs(item.variantAttributes) ?? '';
    final qty = item.quantity ?? 0;
    final price = item.discountedPrice ?? 0;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 6),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                AppText(
                  '$qty x $name',
                  style: context.tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: .ellipsis,
                ),
                if (variant.isNotEmpty)
                  AppText(
                    variant,
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
          AppText(
            '$currency$price',
            style: context.tt.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
