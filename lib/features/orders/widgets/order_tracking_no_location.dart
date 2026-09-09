import 'package:deliveryboy/commons/widgets/app_scaffold.dart';
import 'package:deliveryboy/commons/widgets/app_button.dart';
import 'package:deliveryboy/commons/widgets/app_svg_icon.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/constants/navigation_service.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:deliveryboy/core/theme/app_decorations.dart';
import '../../../core/theme/app_radius.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/commons/widgets/app_text.dart';

class OrderTrackingNoLocation extends StatelessWidget {
  final bool locationServiceOff;
  final VoidCallback onRetry;

  const OrderTrackingNoLocation({
    super.key,
    required this.locationServiceOff,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.all(ThemeConstants.paddingM),
              child: Material(
                color: context.cs.surface,
                borderRadius: AppRadius.r12,
                child: InkWell(
                  onTap: () => AppNavigator.pop(context),
                  borderRadius: AppRadius.r12,
                  child: SizedBox(
                    width: 44,
                    height: 44,
                    child: Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: AppSvgIcon(
                        AssetsConstants.arrowLeftIcon,
                        size: 18,
                        color: context.cs.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsetsDirectional.all(ThemeConstants.spaceXXXL),
                  child: Column(
                    mainAxisSize: .min,
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: AppDecorations.circle(
                          color: context.cs.errorContainer.withValues(
                            alpha: 0.1,
                          ),
                        ),
                        child: AppSvgIcon(
                          AssetsConstants.locationOffIcon,
                          size: 44,
                          color: context.cs.errorContainer,
                        ),
                      ),
                      AppSpacing.h20,
                      AppText(
                        locationServiceOff
                            ? context.translate(
                                LanguageLabelKeys.locationServiceOff,
                              )
                            : context.translate(
                                LanguageLabelKeys.permissionRequired,
                              ),
                        style: context.tt.titleLarge?.copyWith(
                          color: context.cs.onSurface,
                        ),
                        textAlign: .center,
                      ),
                      AppSpacing.h10,
                      AppText(
                        locationServiceOff
                            ? context.translate(
                                LanguageLabelKeys.enableGpsMessage,
                              )
                            : context.translate(
                                LanguageLabelKeys.grantLocationPermission,
                              ),
                        style: context.tt.bodyMedium?.copyWith(
                          color: context.cs.onSurfaceVariant,
                          height: 1.5,
                        ),
                        textAlign: .center,
                      ),
                      AppSpacing.h28,
                      AppButton(
                        label: context.translate(LanguageLabelKeys.tryAgain),
                        height: 50,
                        onPressed: onRetry,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
