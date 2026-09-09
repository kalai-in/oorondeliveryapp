import 'package:deliveryboy/commons/widgets/app_svg_icon.dart';
import 'package:deliveryboy/commons/widgets/app_text_field.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:deliveryboy/core/theme/app_decorations.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/core/theme/app_radius.dart';
import 'package:deliveryboy/core/constants/navigation_service.dart';
import 'package:deliveryboy/commons/widgets/app_text.dart';

/// App-wide top bar supporting a title, back button, actions, or an inline search field.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  // Optional step progress ring shown at the end of the app bar (e.g. "1/2").
  final int? currentStep;
  final int? totalSteps;
  // Search support
  final bool isSearching;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String? searchHint;
  final VoidCallback? onSearchStart;
  final VoidCallback? onSearchCancel;
  // Extra bottom row (e.g. status chips)
  final PreferredSizeWidget? bottom;
  // Custom multi-line title content — overrides the plain [title] Text when set.
  final Widget? titleWidget;

  const CustomAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.currentStep,
    this.totalSteps,
    this.actions,
    this.showBackButton = true,
    this.onBackPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isSearching = false,
    this.searchController,
    this.onSearchChanged,
    this.searchHint,
    this.onSearchStart,
    this.onSearchCancel,
    this.bottom,
    this.titleWidget,
  });

  bool get _hasSearch => onSearchStart != null;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final titleColor = foregroundColor ?? context.cs.onSurface;

    return AppBar(
      backgroundColor: backgroundColor ?? context.cs.surface,
      foregroundColor: titleColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      centerTitle: false, //!isSearching,
      titleSpacing: _hasSearch && isSearching
          ? 16
          : NavigationToolbar.kMiddleSpacing,
      automaticallyImplyLeading: showBackButton,
      title: _hasSearch
          ? AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: 0.92,
                    end: 1.0,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: isSearching
                  ? _AppBarSearchField(
                      key: const ValueKey('search'),
                      controller: searchController!,
                      hint:
                          searchHint ??
                          context.translate(LanguageLabelKeys.searchHint),
                      onChanged: onSearchChanged ?? (_) {},
                    )
                  : AppText(
                      title ?? '',
                      key: const ValueKey('title'),
                      style: context.tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: titleColor,
                        letterSpacing: 0.2,
                      ),
                    ),
            )
          : titleWidget ??
                (title != null
                    ? (subtitle != null
                          ? Column(
                              mainAxisSize: .min,
                              crossAxisAlignment: .start,
                              children: [
                                AppText(
                                  title!,
                                  overflow: .ellipsis,
                                  style: context.tt.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: titleColor,
                                  ),
                                ),
                                AppText(
                                  subtitle!,
                                  overflow: .ellipsis,
                                  style: context.tt.bodySmall?.copyWith(
                                    color: context.cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            )
                          : AppText(
                              title!,
                              style: context.tt.titleMedium?.copyWith(
                                color: titleColor,
                              ),
                            ))
                    : null),
      leading: showBackButton
          ? IconButton(
              icon: Transform.flip(
                flipX: Directionality.of(context) == TextDirection.rtl,
                child: AppSvgIcon(
                  AssetsConstants.arrowLeftIcon,
                  size: 24,
                  color: titleColor,
                ),
              ),
              onPressed: onBackPressed ?? () => AppNavigator.pop(context),
            )
          : null,
      actions: [
        if (_hasSearch)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isSearching
                ? IconButton(
                    key: const ValueKey('close'),
                    icon: AppSvgIcon(
                      AssetsConstants.closeIcon,
                      size: 18,
                      color: context.cs.onSurfaceVariant,
                    ),
                    onPressed: onSearchCancel,
                    color: context.cs.onSurfaceVariant,
                  )
                : IconButton(
                    key: const ValueKey('searchBtn'),
                    icon: AppSvgIcon(
                      AssetsConstants.searchIcon,
                      size: 18,
                      color: context.cs.onSurfaceVariant,
                    ),
                    onPressed: onSearchStart,
                    color: context.cs.onSurfaceVariant,
                  ),
          ),
        ...?actions,
        if (currentStep != null && totalSteps != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: ThemeConstants.paddingL),
            child: _StepProgressRing(
              currentStep: currentStep!,
              totalSteps: totalSteps!,
            ),
          ),
      ],
      bottom: bottom,
    );
  }
}

class _StepProgressRing extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepProgressRing({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentStep + 1) / totalSteps;
    return ExcludeSemantics(
      child: SizedBox(
        width: 34,
        height: 34,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              builder: (_, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 3,
                strokeCap: StrokeCap.round,
                backgroundColor: context.cs.outlineVariant.withValues(
                  alpha: 0.3,
                ),
                valueColor: AlwaysStoppedAnimation(context.cs.primary),
              ),
            ),
            AppText(
              '${currentStep + 1}/$totalSteps',
              style: context.tt.labelSmall?.copyWith(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: context.cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppBarSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _AppBarSearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return Container(
          height: 40,
          decoration: AppDecorations.card(
            color: context.cs.onSurface.withValues(alpha: 0.07),
            borderRadius: AppRadius.r10,
          ),
          child: Row(
            children: [
              AppSpacing.w12,
              AppSvgIcon(
                AssetsConstants.searchIcon,
                size: 18,
                color: context.cs.onSurfaceVariant,
              ),
              AppSpacing.w8,
              Expanded(
                child: AppTextField(
                  controller: controller,
                  autofocus: true,
                  onChanged: onChanged,
                  textInputAction: TextInputAction.search,
                  hintText: hint,
                  variant: AppTextFieldVariant.plain,
                  contentPadding: EdgeInsetsDirectional.zero,
                ),
              ),
              if (value.text.trim().isNotEmpty)
                GestureDetector(
                  onTap: () {
                    controller.clear();
                    onChanged('');
                  },
                  child: Padding(
                    padding: const EdgeInsetsDirectional.all(ThemeConstants.paddingS),
                    child: AppSvgIcon(
                      AssetsConstants.closeCircleIcon,
                      size: 18,
                      color: context.cs.onSurfaceVariant,
                    ),
                  ),
                )
              else
                AppSpacing.w12,
            ],
          ),
        );
      },
    );
  }
}
