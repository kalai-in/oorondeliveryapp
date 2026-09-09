import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/local_storage/settings_hive_box.dart';
import 'package:deliveryboy/core/localization/cubit/language_cubit.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/core/localization/models/language_model.dart';
import 'package:deliveryboy/core/theme/cubit/theme_cubit.dart';
import 'package:deliveryboy/features/profile/widgets/language_sheet.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'profile_menu_widgets.dart';

/// Profile section for changing language and app theme.
class ProfilePreferencesSection extends StatelessWidget {
  const ProfilePreferencesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            /* final themeLabel = switch (themeState.themeMode) {
              ThemeMode.light => context.translate(LanguageLabelKeys.light),
              ThemeMode.dark => context.translate(LanguageLabelKeys.dark),
              _ => context.translate(LanguageLabelKeys.system),
            }; */
            return BlocBuilder<LanguageCubit, LanguageState>(
              builder: (context, langState) {
                String langName;
                if (langState is LanguageLoaded) {
                  final lang = langState.languages
                      .where(
                        (LanguageJsonData l) => l.id == langState.selectedId,
                      )
                      .firstOrNull;
                  final name = lang?.name ?? '';
                  final code =
                      (lang?.code ?? SettingsHiveBox.instance.languageCode)
                          .toUpperCase();
                  langName = name.isNotEmpty ? '$name ($code)' : code;
                } else {
                  langName = SettingsHiveBox.instance.languageCode
                      .toUpperCase();
                }
                return ProfileMenuCard(
                  title: context.translate(LanguageLabelKeys.preferences),
                  items: [
                    ProfileMenuItemData(
                      iconPath: AssetsConstants.languageIcon,
                      label: context.translate(
                        LanguageLabelKeys.changeLanguage,
                      ),
                      trailing: langName,
                      onTap: () => showLanguageSheet(context),
                    ),
                    /* ProfileMenuItemData(
                      iconPath: AssetsConstants.themeIcon,
                      label: context.translate(LanguageLabelKeys.changeTheme),
                      trailing: themeLabel,
                      onTap: () => showAppearanceSheet(context),
                    ), */
                  ],
                );
              },
            );
          },
        ),
        AppSpacing.h12,
      ],
    );
  }
}
