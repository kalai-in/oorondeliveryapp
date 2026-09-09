import 'package:deliveryboy/commons/widgets/app_item_image.dart';
import 'package:deliveryboy/core/constants/app_constants.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:deliveryboy/utils/extensions/size_extensions.dart';
import 'package:deliveryboy/utils/variant_attributes_formatter.dart';
import 'package:flutter/material.dart';
import 'package:deliveryboy/core/theme/app_decorations.dart';
import '../models/order_detail_model.dart';
import '../../../core/theme/app_radius.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/commons/widgets/app_text.dart';

class OrderItemsCard extends StatelessWidget {
  final List<OrderItems> items;
  final String symbol;
  const OrderItemsCard({super.key, required this.items, required this.symbol});

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
              context.translate(LanguageLabelKeys.items),
              style: context.tt.titleSmall?.copyWith(
                color: context.cs.onSurface,
              ),
            ),
          ),
          Divider(height: 1, color: context.cs.outlineVariant),
          ...items.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _ItemRow(item: item, symbol: symbol),
                if (idx < items.length - 1)
                  Divider(height: 1, color: context.cs.outlineVariant),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrderItems item;
  final String symbol;
  const _ItemRow({required this.item, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final variantLabel = formatVariantValues(item.variantAttributes);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, ThemeConstants.paddingM, 14, ThemeConstants.paddingM),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          AppItemImage(
            url: item.image,
            size: context.screenWidth * 0.16,
            borderRadius: AppRadius.r8,
          ),
          AppSpacing.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                Row(
                  crossAxisAlignment: .start,
                  children: [
                    Expanded(
                      child: AppText(
                        '${item.quantity ?? '1'} ${AppConstants.crossQtySymbol} ${item.productName ?? '—'}',
                        style: context.tt.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: context.cs.onSurface,
                        ),
                      ),
                    ),
                    AppSpacing.w8,
                    Column(
                      crossAxisAlignment: .end,
                      children: [
                        AppText(
                          '$symbol${(item.discountedPrice != null && item.discountedPrice != 0) ? item.discountedPrice : (item.price ?? 0)}',
                          style: context.tt.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: context.cs.onSurface,
                          ),
                        ),
                        if (item.discountedPrice != null &&
                            item.discountedPrice != 0 &&
                            item.price != null &&
                            item.discountedPrice != item.price)
                          AppText(
                            '$symbol${item.price}',
                            style: context.tt.labelSmall?.copyWith(
                              color: context.cs.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                if (variantLabel.isNotEmpty) ...[
                  AppSpacing.h4,
                  AppText(
                    variantLabel,
                    style: context.tt.bodySmall?.copyWith(
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
