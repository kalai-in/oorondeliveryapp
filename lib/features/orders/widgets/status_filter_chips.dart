import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/theme/app_radius.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import '../models/order_status_model.dart';
import 'package:deliveryboy/commons/widgets/app_text.dart';

/// Generic horizontal status chip bar shared by orders and return-orders screens.
class StatusFilterChips extends StatelessWidget {
  final List<OrderStatusData> statuses;
  final String? selectedId;
  final ValueChanged<String> onStatusChanged;
  final double height;

  const StatusFilterChips({
    super.key,
    required this.statuses,
    required this.selectedId,
    required this.onStatusChanged,
    this.height = 44,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.cs.surface,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: ListView.separated(
          scrollDirection: .horizontal,
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: 15,
            vertical: height > 44 ? 6 : 5,
          ),
          itemCount: statuses.length,
          separatorBuilder: (_, _) => AppSpacing.w8,
          itemBuilder: (context, index) {
            final entry = statuses[index];
            final isSelected = selectedId == entry.id;
            return ChoiceChip(
              showCheckmark: false,
              label: AppText(entry.statusName ?? ''),
              selected: isSelected,
              onSelected: (_) => onStatusChanged(entry.id ?? ''),
              selectedColor: context.cs.primary,
              backgroundColor: context.cs.surface,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.r25),
              labelStyle: context.tt.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? context.cs.onPrimary
                    : context.cs.onSurfaceVariant,
              ),
              side: BorderSide(
                color: isSelected ? context.cs.primary : context.cs.outline,
              ),
              padding: const EdgeInsetsDirectional.symmetric(horizontal: ThemeConstants.paddingXS),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            );
          },
        ),
      ),
    );
  }
}
