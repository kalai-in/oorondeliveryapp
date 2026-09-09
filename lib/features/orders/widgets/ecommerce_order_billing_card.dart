import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/features/orders/utils/payment_breakdown.dart';
import 'package:deliveryboy/features/orders/widgets/bill_row.dart';
import 'package:deliveryboy/features/orders/widgets/payment_summary_section.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import '../models/ecommerce_order_model.dart';
import '../models/order_status.dart';
import '../../../core/theme/app_decorations.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/commons/widgets/app_text.dart';

class EcommerceOrderBillingCard extends StatelessWidget {
  final EcommerceOrderDataModel order;
  final String symbol;
  const EcommerceOrderBillingCard({
    super.key,
    required this.order,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(ThemeConstants.paddingL),
      decoration: AppDecorations.shadowedCard(
        color: Theme.of(context).cardColor,
        shadowColor: context.cs.shadow,
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          AppText(
            context.translate(LanguageLabelKeys.billSummary),
            style: context.tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.cs.onSurface,
            ),
          ),
          AppSpacing.h12,
          BillRow(
            label: context.translate(LanguageLabelKeys.subTotal),
            value: '$symbol${order.subTotal ?? 0}',
            suffixLabel: (order.taxAmount ?? 0) > 0
                ? context.translate(LanguageLabelKeys.inclTax)
                : null,
          ),
          AppSpacing.h8,
          BillRow(
            label: context.translate(LanguageLabelKeys.deliveryCharge),
            value: '$symbol${order.deliveryCharge ?? 0}',
          ),
          if ((order.additionalCharges ?? []).isNotEmpty)
            ...order.additionalCharges!.map(
              (c) => Padding(
                padding: const EdgeInsetsDirectional.only(top: ThemeConstants.paddingS),
                child: BillRow(
                  label: c.name ?? '',
                  value: '$symbol${c.amount ?? 0}',
                ),
              ),
            ),
          if ((order.surgeCharges ?? []).isNotEmpty)
            ...order.surgeCharges!.map(
              (c) => Padding(
                padding: const EdgeInsetsDirectional.only(top: ThemeConstants.paddingS),
                child: BillRow(
                  label: c.label ?? '',
                  value: '$symbol${c.charge ?? 0}',
                ),
              ),
            ),
          if ((order.promoDiscount ?? 0) > 0) ...[
            AppSpacing.h8,
            BillRow(
              label: context.translate(LanguageLabelKeys.promoDiscount),
              value: '-$symbol${order.promoDiscount}',
              isDiscount: true,
            ),
          ],
          if ((order.refundAmount ?? 0) > 0) ...[
            AppSpacing.h8,
            BillRow(
              label: context.translate(LanguageLabelKeys.refundAmount),
              value: '$symbol${order.refundAmount}',
              isDiscount: true,
            ),
          ],
          AppSpacing.h8,
          PaymentSummarySection(
            symbol: symbol,
            breakdown: PaymentBreakdown.compute(
              walletAmount: order.walletBalance,
              remainingAmount: order.finalTotal,
              paymentMethod: order.paymentMethod,
              isDelivered: order.activeStatus == OrderStatus.delivered.id,
              refundAmount: order.refundAmount,
            ),
          ),
        ],
      ),
    );
  }
}
