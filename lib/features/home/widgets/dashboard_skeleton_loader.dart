import 'package:deliveryboy/commons/widgets/shimmer_loading.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/theme/app_radius.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Shimmering placeholder that mirrors the home dashboard layout
/// (performance tiles, overview tiles, status grid, trend and rate cards)
/// while [DashboardCubit] is loading.
class DashboardSkeletonLoader extends StatelessWidget {
  const DashboardSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingXL, ThemeConstants.paddingL, 0),
        child: Column(
          crossAxisAlignment: .start,
          children: [
            // Today's performance — section title + date chip
            const Row(
              children: [
                ShimmerBox(width: 150, height: 16, borderRadius: AppRadius.r8),
                Spacer(),
                ShimmerBox(width: 84, height: 24, borderRadius: AppRadius.r20),
              ],
            ),
            AppSpacing.h16,
            const ShimmerCardRow(height: 108),
            AppSpacing.h16,
            const ShimmerCardRow(height: 108),
            AppSpacing.h16,

            // Delivery overview — stat tiles
            const ShimmerBox(
              width: 140,
              height: 16,
              borderRadius: AppRadius.r8,
            ),
            AppSpacing.h12,
            const ShimmerCardRow(height: 70, spacing: 12),
            AppSpacing.h12,
            const ShimmerCardRow(height: 70, spacing: 12),
            AppSpacing.h14,

            // Active orders status grid
            const ShimmerBox(height: 170, borderRadius: AppRadius.r16),
            AppSpacing.h14,

            // Earnings trend card
            const ShimmerBox(height: 210, borderRadius: AppRadius.r16),
            AppSpacing.h14,

            // Delivery performance card
            const ShimmerBox(
              width: 160,
              height: 16,
              borderRadius: AppRadius.r8,
            ),
            AppSpacing.h10,
            const ShimmerBox(height: 200, borderRadius: AppRadius.r16),
            AppSpacing.h90,
          ],
        ),
      ),
    );
  }
}
