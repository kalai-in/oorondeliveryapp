import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/features/orders/utils/payment_breakdown.dart';
import 'package:deliveryboy/features/orders/widgets/bill_row.dart';
import 'package:deliveryboy/features/orders/widgets/payment_summary_section.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:deliveryboy/core/theme/app_decorations.dart';
import '../models/order_detail_model.dart';
import '../models/order_status.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/commons/widgets/app_text.dart';

class OrderBillingCard extends StatelessWidget {
  final Order? order;
  final OrderDetailData detail;
  final String symbol;
  const OrderBillingCard({
    super.key,
    required this.order,
    required this.detail,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: ThemeConstants.paddingL),
      decoration: AppDecorations.shadowedCard(
        color: Theme.of(context).cardColor,
        shadowColor: context.cs.shadow,
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, ThemeConstants.paddingM),
            child: AppText(
              context.translate(LanguageLabelKeys.billSummary),
              style: context.tt.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: context.cs.onSurface,
              ),
            ),
          ),
          Divider(height: 1, color: context.cs.outlineVariant),
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(14, ThemeConstants.paddingM, 14, 14),
            child: Column(
              children: [
                BillRow(
                  label: context.translate(LanguageLabelKeys.subTotal),
                  value: '$symbol${order?.total ?? '0'}',
                  suffixLabel: (order?.taxAmount ?? 0) != 0
                      ? context.translate(LanguageLabelKeys.inclTax)
                      : null,
                ),
                BillRow(
                  label: context.translate(LanguageLabelKeys.deliveryCharge),
                  value: '$symbol${order?.deliveryCharge ?? '0'}',
                ),
                if ((order?.discount ?? 0) != 0)
                  BillRow(
                    label: context.translate(LanguageLabelKeys.discount),
                    value: '-$symbol${order?.discount}',
                    isDiscount: true,
                  ),
                if ((order?.promoDiscount ?? 0) != 0)
                  BillRow(
                    label: context.translate(LanguageLabelKeys.promoDiscount),
                    value: '-$symbol${order?.promoDiscount}',
                    isDiscount: true,
                  ),
                if ((detail.order?.additionalCharges ?? []).isNotEmpty)
                  ...detail.order!.additionalCharges!.map(
                    (c) => BillRow(
                      label: c.name ?? '',
                      value: '$symbol${c.amount ?? '0'}',
                    ),
                  ),
                if ((detail.order?.surgeCharges ?? []).isNotEmpty)
                  ...detail.order!.surgeCharges!.map(
                    (c) => BillRow(
                      label: c.label ?? '',
                      value: '$symbol${c.charge ?? '0'}',
                    ),
                  ),
                if ((order?.refundAmount ?? 0) != 0)
                  BillRow(
                    label: context.translate(LanguageLabelKeys.refundAmount),
                    value: '$symbol${order?.refundAmount}',
                    isDiscount: true,
                  ),
                AppSpacing.h8,
                PaymentSummarySection(
                  symbol: symbol,
                  breakdown: PaymentBreakdown.compute(
                    walletAmount: order?.walletBalance,
                    remainingAmount: order?.finalTotal,
                    paymentMethod: order?.paymentMethod,
                    isDelivered:
                        order?.activeStatus == OrderStatus.delivered.id,
                    refundAmount: order?.refundAmount,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
