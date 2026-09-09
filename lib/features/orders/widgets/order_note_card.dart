import 'package:deliveryboy/commons/widgets/app_svg_icon.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/core/theme/app_radius.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:deliveryboy/core/theme/app_decorations.dart';
import 'package:deliveryboy/commons/widgets/app_text.dart';

/// Sticky-note style callout for the customer's delivery instruction —
/// distinct from plain label/value rows so it reads as a note, not raw data.
class OrderNoteCard extends StatelessWidget {
  final String note;
  const OrderNoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(bottom: ThemeConstants.paddingL),
      padding: const EdgeInsetsDirectional.all(14),
      decoration: AppDecorations.card(
        color: context.cs.surface,
        borderRadius: AppRadius.r14,
        border: Border.all(color: context.cs.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: AppDecorations.circle(
              color: context.cs.errorContainer.withValues(alpha: 0.12),
            ),
            child: AppSvgIcon(
              AssetsConstants.noteIcon,
              size: 17,
              color: context.cs.errorContainer,
            ),
          ),
          AppSpacing.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: .start,
              children: [
                AppText(
                  context.translate(LanguageLabelKeys.orderNote),
                  style: context.tt.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: context.cs.onSurface,
                  ),
                ),
                AppSpacing.h4,
                AppText(
                  note,
                  style: context.tt.labelMedium?.copyWith(
                    fontStyle: .italic,
                    color: context.cs.onSurfaceVariant,
                    height: 1.4,
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
