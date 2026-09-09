import 'package:deliveryboy/commons/cubit/connectivity_cubit.dart';
import 'package:deliveryboy/commons/widgets/app_no_internet_widget.dart';
import 'package:deliveryboy/commons/widgets/app_scaffold.dart';
import 'package:deliveryboy/commons/widgets/custom_app_bar.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/features/profile/cubit/profile_detail_cubit.dart';
import 'package:deliveryboy/features/profile/widgets/profile_account_section.dart';
import 'package:deliveryboy/features/profile/widgets/profile_header.dart';
import 'package:deliveryboy/features/profile/widgets/profile_preferences_section.dart';
import 'package:deliveryboy/features/profile/widgets/profile_quick_help_section.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Main profile tab showing header, preferences, help, and account sections.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivityConnected) {
          context.read<ProfileDetailCubit>().loadProfile();
        }
      },
      builder: (context, connectivityState) {
        final isOffline = connectivityState is ConnectivityDisconnected;
        return AppScaffold(
          appBar: CustomAppBar(
            title: context.translate(LanguageLabelKeys.myProfile),
            showBackButton: false,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          // App bar stays mounted while offline so the screen keeps its
          // identity instead of being replaced wholesale.
          body: isOffline
              ? AppNoInternetFullScreen(
                  embedded: true,
                  onRetry: () =>
                      context.read<ProfileDetailCubit>().loadProfile(),
                )
              : CustomScrollView(
                  slivers: [
                    const SliverToBoxAdapter(child: ProfileHeader()),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsetsDirectional.fromSTEB(
                          ThemeConstants.paddingL,
                          ThemeConstants.paddingXS,
                          ThemeConstants.paddingL,
                          0,
                        ),
                        child: Column(
                          crossAxisAlignment: .start,
                          children: const [
                            ProfilePreferencesSection(),
                            ProfileQuickHelpSection(),
                            ProfileAccountSection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
