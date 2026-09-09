import 'package:flutter/material.dart';
import '../../core/theme/app_radius.dart';
import 'shimmer_loading.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';

/// Shimmering placeholder list used while paginated content is loading.
class ListSkeletonLoader extends StatelessWidget {
  final int itemCount;
  final bool showHeroCard;

  const ListSkeletonLoader({
    super.key,
    this.itemCount = 6,
    this.showHeroCard = false,
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerLoading(
      child: ListView.builder(
        padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingM, ThemeConstants.paddingL, ThemeConstants.spaceXXXL),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount + (showHeroCard ? 1 : 0),
        itemBuilder: (context, index) {
          if (showHeroCard && index == 0) {
            return const Padding(
              padding: EdgeInsetsDirectional.only(bottom: ThemeConstants.paddingL),
              child: ShimmerBox(height: 140, borderRadius: AppRadius.r20),
            );
          }
          return const Padding(
            padding: EdgeInsetsDirectional.only(bottom: ThemeConstants.paddingM),
            child: ShimmerBox(height: 92),
          );
        },
      ),
    );
  }
}
