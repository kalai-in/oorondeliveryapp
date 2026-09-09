import 'package:deliveryboy/commons/widgets/app_snack_bar.dart';
import 'package:deliveryboy/commons/widgets/app_svg_icon.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/core/theme/app_decorations.dart';
import 'package:deliveryboy/utils/app_date_formatter.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:deliveryboy/utils/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/ecommerce_order_model.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'order_action_buttons.dart';
import 'package:deliveryboy/commons/widgets/app_text.dart';

class EcommerceOrderCustomerInfoCard extends StatelessWidget {
  final EcommerceOrderDataModel order;
  const EcommerceOrderCustomerInfoCard({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final orderIdText = (order.orderNumber ?? 0).toString();

    final rows = <Widget>[
      _LabelValueRow(
        label: context.translate(LanguageLabelKeys.orderId),
        value: orderIdText,
        trailing: orderIdText.isEmpty
            ? null
            : InkWell(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: orderIdText));
                  AppSnackBar.show(
                    context: context,
                    message: context.translate(LanguageLabelKeys.copied),
                    type: SnackBarType.success,
                  );
                },
                child: AppSvgIcon(
                  AssetsConstants.copyIcon,
                  size: 16,
                  color: context.cs.onSurfaceVariant,
                ),
              ),
      ),
      if (order.storeName.isNotNullOrEmpty)
        _LabelValueRow(
          label: context.translate(LanguageLabelKeys.store),
          value: order.storeName!,
        ),
      if (order.paymentMethod.isNotNullOrEmpty)
        _LabelValueRow(
          label: context.translate(LanguageLabelKeys.paymentMethod),
          value: order.paymentMethod!,
        ),
      if (order.orderMobile.isNotNullOrEmpty)
        _LabelValueRow(
          label: context.translate(LanguageLabelKeys.mobile),
          value: order.orderMobile!,
          trailing: InkWell(
            onTap: () => launchCall(order.orderMobile),
            child: Container(
              padding: const EdgeInsetsDirectional.all(6),
              decoration: AppDecorations.circle(
                color: context.cs.primaryContainer,
              ),
              child: AppSvgIcon(
                AssetsConstants.phoneIcon,
                size: 14,
                color: context.cs.primary,
              ),
            ),
          ),
        ),
      if (order.orderAddress.isNotNullOrEmpty)
        _LabelValueRow(
          label: context.translate(LanguageLabelKeys.deliverTo),
          value: order.orderAddress!,
          maxLines: 2,
        ),
      if (order.orderNote.isNotNullOrEmpty)
        _LabelValueRow(
          label: context.translate(LanguageLabelKeys.orderNote),
          value: order.orderNote!,
          maxLines: 3,
        ),
      if ((order.orderCreatedAt ?? order.date).isNotNullOrEmpty)
        _LabelValueRow(
          label: context.translate(LanguageLabelKeys.orderPlaced),
          value:
              '${context.translate(LanguageLabelKeys.placedOn)} ${AppDateFormatter.formatDateTime(order.date)}',
        ),
    ];

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
            context.translate(LanguageLabelKeys.orderDetails),
            style: context.tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.cs.onSurface,
            ),
          ),
          AppSpacing.h12,
          for (var i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1) ...[
              AppSpacing.h10,
              Divider(height: 1, color: context.cs.outlineVariant),
              AppSpacing.h10,
            ],
          ],
        ],
      ),
    );
  }
}

class _LabelValueRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;
  final int maxLines;
  const _LabelValueRow({
    required this.label,
    required this.value,
    this.trailing,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: .start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: .start,
            children: [
              AppText(
                label,
                style: context.tt.labelSmall?.copyWith(
                  color: context.cs.onSurfaceVariant,
                ),
              ),
              AppSpacing.h3,
              AppText(
                value,
                style: context.tt.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: context.cs.onSurface,
                ),
                maxLines: maxLines,
                overflow: .ellipsis,
              ),
            ],
          ),
        ),
        if (trailing != null) ...[AppSpacing.w8, trailing!],
      ],
    );
  }
}
