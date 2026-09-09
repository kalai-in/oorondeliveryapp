import 'package:deliveryboy/commons/widgets/app_item_image.dart';
import 'package:deliveryboy/core/constants/app_constants.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:deliveryboy/utils/extensions/size_extensions.dart';
import 'package:deliveryboy/utils/extensions/string_extensions.dart';
import 'package:deliveryboy/utils/variant_attributes_formatter.dart';
import 'package:flutter/material.dart';
import '../models/ecommerce_order_model.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_radius.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/commons/widgets/app_text.dart';

class EcommerceOrderDetailItemsCard extends StatelessWidget {
  final EcommerceOrderDataModel order;
  final String symbol;
  const EcommerceOrderDetailItemsCard({
    super.key,
    required this.order,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    final otherItems = order.otherItems ?? [];

    return Column(
      crossAxisAlignment: .start,
      children: [
        Container(
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
                context.translate(LanguageLabelKeys.items),
                style: context.tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.cs.onSurface,
                ),
              ),
              AppSpacing.h10,
              Divider(height: 1, color: context.cs.outlineVariant),
              AppSpacing.h12,
              _MainItemRow(order: order, symbol: symbol),
            ],
          ),
        ),
        if (otherItems.isNotEmpty) ...[
          AppSpacing.h12,
          Container(
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
                  '${context.translate(LanguageLabelKeys.otherItemsInOrder)} (${otherItems.length})',
                  style: context.tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.cs.onSurface,
                  ),
                ),
                AppSpacing.h12,
                ...otherItems.asMap().entries.map((entry) {
                  final i = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: EdgeInsetsDirectional.only(top: i == 0 ? 0 : 12),
                    child: _OtherItemRow(item: item, symbol: symbol),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MainItemRow extends StatelessWidget {
  final EcommerceOrderDataModel order;
  final String symbol;
  const _MainItemRow({required this.order, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final imgSize = context.screenWidth * 0.18;
    final variant = formatVariantPairs(order.variantAttributes) ?? '';
    final price = (order.discountedPrice != null && order.discountedPrice != 0)
        ? order.discountedPrice!
        : (order.price ?? 0);

    return Row(
      crossAxisAlignment: .start,
      children: [
        AppItemImage(url: order.image, size: imgSize),
        AppSpacing.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              AppText(
                '${order.quantity ?? 1} ${AppConstants.crossQtySymbol} ${order.productName ?? order.name ?? '—'}',
                style: context.tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.cs.onSurface,
                ),
                maxLines: 2,
                overflow: .ellipsis,
              ),
              if (variant.isNotEmpty) ...[
                AppSpacing.h4,
                AppText(
                  variant,
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
                  if (order.discountedPrice != null &&
                      order.discountedPrice != 0 &&
                      order.price != null &&
                      order.discountedPrice != order.price) ...[
                    AppSpacing.w8,
                    AppText(
                      '$symbol${order.price}',
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
    );
  }
}

class _OtherItemRow extends StatelessWidget {
  final OtherItems item;
  final String symbol;
  const _OtherItemRow({required this.item, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final imgSize = context.screenWidth * 0.14;

    return Row(
      crossAxisAlignment: .start,
      children: [
        AppItemImage(
          url: item.image,
          size: imgSize,
          borderRadius: AppRadius.r8,
          iconSize: 20,
        ),
        AppSpacing.w12,
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              AppText(
                '${item.quantity ?? 1} ${AppConstants.crossQtySymbol} ${item.productName ?? '—'}',
                style: context.tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: context.cs.onSurface,
                ),
                maxLines: 2,
                overflow: .ellipsis,
              ),
              if (item.statusName.isNotNullOrEmpty) ...[
                AppSpacing.h4,
                AppText(
                  item.statusName!,
                  style: context.tt.bodySmall?.copyWith(
                    color: context.cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        AppSpacing.w8,
        AppText(
          '$symbol${item.finalTotal ?? 0}',
          style: context.tt.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
