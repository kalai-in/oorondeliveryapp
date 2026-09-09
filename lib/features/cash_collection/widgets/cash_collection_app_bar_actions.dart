import 'package:deliveryboy/commons/widgets/app_svg_icon.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:deliveryboy/core/theme/app_decorations.dart';
import 'package:deliveryboy/core/theme/app_radius.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/cash_collection_cubit.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';

/// App-bar action buttons (date-range filter, clear filters) for the cash collection screen.
class CashCollectionAppBarActions extends StatelessWidget {
  final VoidCallback onPickDateRange;
  final VoidCallback onClearFilters;

  const CashCollectionAppBarActions({
    super.key,
    required this.onPickDateRange,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CashCollectionCubit, CashCollectionState>(
      builder: (context, state) {
        final cubit = context.read<CashCollectionCubit>();
        final hasDate = cubit.startDate != null || cubit.endDate != null;
        return Row(
          mainAxisSize: .min,
          children: [
            Stack(
              clipBehavior: .none,
              children: [
                IconButton(
                  icon: AppSvgIcon(
                    AssetsConstants.dateIcon,
                    size: 18,
                    color: hasDate
                        ? context.cs.primary
                        : context.cs.onSurfaceVariant,
                  ),
                  onPressed: onPickDateRange,
                  tooltip: hasDate
                      ? '${cubit.startDate} → ${cubit.endDate}'
                      : context.translate(LanguageLabelKeys.dateRange),
                ),
                if (hasDate)
                  PositionedDirectional(
                    end: 10,
                    top: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: AppDecorations.circle(
                        color: context.cs.primary,
                      ),
                    ),
                  ),
              ],
            ),
            if (cubit.hasActiveFilters) ...[
              AppSpacing.w4,
              Tooltip(
                message: context.translate(LanguageLabelKeys.clearFilters),
                child: InkWell(
                  onTap: onClearFilters,
                  borderRadius: AppRadius.r10,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: AppDecorations.outlinedCard(
                      color: context.cs.surface,
                      borderColor: context.cs.outline,
                    ),
                    child: AppSvgIcon(
                      AssetsConstants.closeIcon,
                      size: 16,
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
            AppSpacing.w4,
          ],
        );
      },
    );
  }
}
