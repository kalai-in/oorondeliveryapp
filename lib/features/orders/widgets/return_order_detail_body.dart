import 'package:deliveryboy/commons/widgets/app_item_image.dart';
import 'package:deliveryboy/commons/widgets/app_scaffold.dart';
import 'package:deliveryboy/commons/widgets/app_svg_icon.dart';
import 'package:deliveryboy/commons/widgets/custom_app_bar.dart';
import 'package:deliveryboy/core/constants/app_constants.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/core/theme/app_radius.dart';
import 'package:deliveryboy/features/orders/utils/payment_breakdown.dart';
import 'package:deliveryboy/features/orders/widgets/bill_row.dart';
import 'package:deliveryboy/features/orders/widgets/payment_summary_section.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:deliveryboy/utils/extensions/size_extensions.dart';
import 'package:deliveryboy/utils/extensions/string_extensions.dart';
import 'package:deliveryboy/utils/variant_attributes_formatter.dart';
import 'package:flutter/material.dart';
import 'package:deliveryboy/core/theme/app_decorations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/return_order_detail_cubit.dart';
import '../models/return_order_model.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'order_appbar_title.dart';
import 'order_timeline_card.dart';
import 'pickup_delivery_card.dart';
import 'return_order_status_sheet.dart';
import 'package:deliveryboy/commons/widgets/app_text.dart';

class ReturnOrderDetailBody extends StatelessWidget {
  final ReturnRequestData detail;
  const ReturnOrderDetailBody({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final bottomPad = context.bottomSafePadding;
    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      applyBottomInset: false,
      extendBody: false,
      appBar: CustomAppBar(
        showBackButton: true,
        titleWidget: OrderAppBarTitle(
          statusLabel: detail.orderStatusName ?? '—',
          idLine: detail.returnNumber?.toString() ?? '—',
        ),
      ),
      bottomNavigationBar: ReturnOrderStatusActionButton(detail: detail),
      body: RefreshIndicator(
        color: context.cs.primary,
        onRefresh: () => context.read<ReturnOrderDetailCubit>().loadDetail(
          detail.id?.toString() ?? '',
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingL, ThemeConstants.paddingL, bottomPad),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              PickupDeliveryCard(
                pickupName:
                    detail.pickupAddress?.name ?? "",
                pickupAddress:
                    detail.pickupAddress?.address ?? "",
                pickupPhone:
                    detail.pickupAddress?.mobile ?? "",
                pickupLatitude:
                    detail.pickupAddress?.latitude ?? "",
                pickupLongitude:
                    detail.pickupAddress?.longitude ?? "",
                deliveryName: detail.storeInfo?.storeName,
                deliveryAddress: detail.storeInfo?.formattedAddress,
                deliveryPhone: detail.storeInfo?.mobile,
                deliveryLatitude: detail.storeInfo?.latitude,
                deliveryLongitude: detail.storeInfo?.longitude,
              ),
              if (detail.timeline?.isNotEmpty ?? false) ...[
                AppSpacing.h12,
                OrderTimelineCard(timeline: detail.timeline!),
              ],
              AppSpacing.h12,
              _ProductCard(detail: detail),
              if (detail.returnReason.isNotNullOrEmpty ||
                  detail.remarks.isNotNullOrEmpty ||
                  detail.rejectReason.isNotNullOrEmpty) ...[
                AppSpacing.h12,
                _ReturnInfoCard(detail: detail),
              ],
              AppSpacing.h12,
              _PaymentCard(detail: detail),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Product ─────────────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final ReturnRequestData detail;
  const _ProductCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final symbol = detail.currency ?? "";
    final imgSize = context.screenWidth * 0.18;
    final image = detail.returnItem?.image;
    final variantText = formatVariantValues(
      detail.returnItem?.variantAttributes,
    );
    final price =
        (detail.discountedPrice != null && detail.discountedPrice != 0)
        ? detail.discountedPrice!
        : (detail.price ?? 0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(14),
      decoration: AppDecorations.shadowedCard(
        color: Theme.of(context).cardColor,
        shadowColor: context.cs.shadow,
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          AppItemImage(url: image, size: imgSize),
          AppSpacing.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                AppText(
                  '${detail.quantity ?? 1} ${AppConstants.crossQtySymbol} ${detail.productName ?? '—'}',
                  style: context.tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: context.cs.onSurface,
                  ),
                  maxLines: 2,
                  overflow: .ellipsis,
                ),
                if (variantText.isNotEmpty) ...[
                  AppSpacing.h4,
                  AppText(
                    variantText,
                    style: context.tt.bodySmall?.copyWith(
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                ],
                AppSpacing.h8,
                Row(
                  children: [
                    AppText(
                      '$symbol$price',
                      style: context.tt.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.cs.primary,
                      ),
                    ),
                    if (detail.discountedPrice != null &&
                        detail.discountedPrice != 0 &&
                        detail.price != null &&
                        detail.discountedPrice != detail.price) ...[
                      AppSpacing.w8,
                      AppText(
                        '$symbol${detail.price}',
                        style: context.tt.labelSmall?.copyWith(
                          color: context.cs.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Return info ──────────────────────────────────────────────────────────────

class _ReturnInfoCard extends StatelessWidget {
  final ReturnRequestData detail;
  const _ReturnInfoCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(14),
      decoration: AppDecorations.shadowedCard(
        color: Theme.of(context).cardColor,
        shadowColor: context.cs.shadow,
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          if (detail.returnReason.isNotNullOrEmpty ||
              detail.remarks.isNotNullOrEmpty) ...[
            Row(
              children: [
                AppSvgIcon(
                  AssetsConstants.noteIcon,
                  size: 17,
                  color: context.cs.primary,
                ),
                AppSpacing.w6,
                Expanded(
                  child: AppText(
                    context.translate(LanguageLabelKeys.whyReturnQuestion),
                    style: context.tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 10),
              child: Divider(height: 1, color: context.cs.outlineVariant),
            ),
            if (detail.returnReason.isNotNullOrEmpty) ...[
              AppSpacing.h10,
              AppText(
                detail.returnReason!,
                style: context.tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: context.cs.onSurface,
                ),
              ),
            ],
            if (detail.remarks.isNotNullOrEmpty) ...[
              AppSpacing.h6,
              AppText(
                detail.remarks!,
                style: context.tt.bodySmall?.copyWith(
                  color: context.cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
          if (detail.rejectReason.isNotNullOrEmpty) ...[
            if (detail.returnReason.isNotNullOrEmpty ||
                detail.remarks.isNotNullOrEmpty)
              AppSpacing.h12,
            _InfoBlock(
              icon: AssetsConstants.closeCircleIcon,
              label: context.translate(LanguageLabelKeys.cancelReason),
              value: detail.rejectReason!,
              color: context.cs.onErrorContainer,
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  const _InfoBlock({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(10),
      decoration: AppDecorations.card(
        color: color.withValues(alpha: 0.06),
        borderRadius: AppRadius.r10,
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              AppSvgIcon(icon, size: 15, color: color),
              AppSpacing.w6,
              AppText(
                label,
                style: context.tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          AppSpacing.h6,
          AppText(
            value,
            style: context.tt.bodySmall?.copyWith(color: context.cs.onSurface),
          ),
        ],
      ),
    );
  }
}

// ─── Payment ──────────────────────────────────────────────────────────────────

class _PaymentCard extends StatelessWidget {
  final ReturnRequestData detail;
  const _PaymentCard({required this.detail});

  @override
  Widget build(BuildContext context) {
    final symbol = detail.currency ?? "";
    final item = detail.returnItem;

    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.all(14),
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
            value: '$symbol${item?.subTotal ?? 0}',
            suffixLabel: (item?.taxAmount ?? 0) != 0
                ? context.translate(LanguageLabelKeys.inclTax)
                : null,
          ),
          if ((item?.additionalCharges ?? []).isNotEmpty)
            ...item!.additionalCharges!.map(
              (c) => Padding(
                padding: const EdgeInsetsDirectional.only(top: ThemeConstants.paddingS),
                child: BillRow(
                  label: c.name ?? '',
                  value: '$symbol${c.amount ?? 0}',
                ),
              ),
            ),
          if ((item?.surgeCharges ?? []).isNotEmpty)
            ...item!.surgeCharges!.map(
              (c) => Padding(
                padding: const EdgeInsetsDirectional.only(top: ThemeConstants.paddingS),
                child: BillRow(
                  label: c.label ?? '',
                  value: '$symbol${c.charge ?? 0}',
                ),
              ),
            ),
          if ((item?.promoDiscount ?? 0) != 0) ...[
            AppSpacing.h8,
            BillRow(
              label: item?.promoCode.isNotNullOrEmpty ?? false
                  ? '${context.translate(LanguageLabelKeys.promoDiscount)} (${item!.promoCode})'
                  : context.translate(LanguageLabelKeys.promoDiscount),
              value: '-$symbol${item!.promoDiscount}',
              isDiscount: true,
            ),
          ],
          AppSpacing.h8,
          PaymentSummarySection(
            symbol: symbol,
            breakdown: PaymentBreakdown.compute(
              walletAmount: item?.walletBalance,
              remainingAmount: item?.finalTotal,
              paymentMethod: item?.paymentMethod ?? detail.paymentMethod,
              isDelivered:
                  detail.returnStatusEnum ==
                  ReturnOrderStatus.receivedFromCustomer,
              refundAmount: item?.refundAmount,
            ),
          ),
        ],
      ),
    );
  }
}
