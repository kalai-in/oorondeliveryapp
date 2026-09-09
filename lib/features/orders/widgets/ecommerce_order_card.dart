import 'package:deliveryboy/commons/widgets/app_item_image.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/core/theme/app_decorations.dart';
import 'package:deliveryboy/core/theme/app_radius.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/features/orders/utils/payment_breakdown.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:deliveryboy/utils/extensions/size_extensions.dart';
import 'package:deliveryboy/utils/variant_attributes_formatter.dart';
import 'package:flutter/material.dart';
import '../models/ecommerce_order_model.dart';
import '../models/order_status.dart';
import 'package:deliveryboy/commons/widgets/app_text.dart';
import 'order_card_shared.dart';

class EcommerceOrderCard extends StatelessWidget {
  final EcommerceOrderDataModel order;
  final VoidCallback? onTap;

  const EcommerceOrderCard({super.key, required this.order, this.onTap});

  @override
  Widget build(BuildContext context) {
    final symbol = order.currency ?? "";
    final dividerColor = context.cs.outlineVariant;
    final otherItemsCount = order.otherItems?.length ?? 0;
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
              date: order.date,
              activeStatus: order.activeStatus?.toString(),
              orderStatusName: order.orderItemStatus,
            ),
            Padding(
              padding: const EdgeInsetsDirectional.symmetric(vertical: 10),
              child: Divider(height: 1, color: dividerColor),
            ),
            _ProductRow(order: order, currency: symbol),
            if (otherItemsCount > 0)
              Padding(
                padding: const EdgeInsetsDirectional.only(top: ThemeConstants.paddingXS),
                child: AppText(
                  '+$otherItemsCount ${context.translate(LanguageLabelKeys.moreItems)}',
                  style: context.tt.bodySmall?.copyWith(
                    color: context.cs.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
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

class _ProductRow extends StatelessWidget {
  final EcommerceOrderDataModel order;
  final String? currency;
  const _ProductRow({required this.order, this.currency});

  @override
  Widget build(BuildContext context) {
    final variant = formatVariantPairs(order.variantAttributes) ?? '';
    final price = order.discountedPrice ?? 0;

    return Row(
      crossAxisAlignment: .start,
      children: [
        AppItemImage(
          url: order.image,
          size: context.screenWidth * 0.13,
          borderRadius: AppRadius.r8,
          iconSize: 20,
        ),
        AppSpacing.w10,
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              AppText(
                '${order.quantity ?? 1} x ${order.productName ?? order.name ?? '—'}',
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
          style: context.tt.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
