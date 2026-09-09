import 'package:deliveryboy/commons/widgets/app_scaffold.dart';
import 'package:deliveryboy/commons/widgets/custom_app_bar.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/core/routes/route_names.dart';
import 'package:deliveryboy/features/profile/widgets/profile_dialogs.dart';
import 'package:deliveryboy/features/profile/widgets/profile_menu_widgets.dart';
import 'package:flutter/material.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:deliveryboy/core/constants/navigation_service.dart';

/// Screen showing the account section (settings, logout) of the profile.
class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: context.translate(LanguageLabelKeys.settings),
      ),
      body: ListView(
        padding: const EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingL, ThemeConstants.paddingL, 28),
        children: [
          ProfileMenuCard(
            title: context.translate(LanguageLabelKeys.general),
            items: [
              ProfileMenuItemData(
                iconPath: AssetsConstants.notificationIcon,
                label: context.translate(LanguageLabelKeys.notifications),
                onTap: () =>
                    AppNavigator.pushNamed(context, RouteNames.notifications),
              ),
              ProfileMenuItemData(
                iconPath: AssetsConstants.passwordIcon,
                label: context.translate(LanguageLabelKeys.changePassword),
                onTap: () => showChangePasswordSheet(context),
              ),
              ProfileMenuItemData(
                iconPath: AssetsConstants.deleteIcon,
                label: context.translate(LanguageLabelKeys.deleteAccount),
                onTap: () => showDeleteAccountDialog(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
