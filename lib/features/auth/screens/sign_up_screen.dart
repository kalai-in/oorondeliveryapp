import 'package:deliveryboy/commons/cubit/countries_cubit.dart';
import 'package:deliveryboy/commons/cubit/zones_cubit.dart';
import 'package:deliveryboy/commons/widgets/app_button.dart';
import 'package:deliveryboy/commons/widgets/app_scaffold.dart';
import 'package:deliveryboy/commons/widgets/app_snack_bar.dart';
import 'package:deliveryboy/commons/widgets/custom_app_bar.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/core/routes/route_names.dart';
import 'package:deliveryboy/features/auth/widgets/register_form.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:deliveryboy/utils/extensions/size_extensions.dart';
import 'package:flutter/material.dart';
import 'package:deliveryboy/core/theme/app_decorations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/sign_up_cubit.dart';
import 'package:deliveryboy/core/constants/navigation_service.dart';

/// Screen for delivery boy registration.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _registerFormKey = GlobalKey<RegisterFormState>();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SignUpCubit()),
        BlocProvider(create: (_) => ZonesCubit()),
        BlocProvider.value(value: context.read<CountriesCubit>()),
      ],
      child: AppScaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: context.translate(LanguageLabelKeys.createAccount),
          subtitle: context.translate(LanguageLabelKeys.signUpToGetStarted),
          showBackButton: true,
        ),
        bottomNavigationBar: BlocBuilder<SignUpCubit, SignUpState>(
          builder: (context, state) {
            return Container(
              padding: EdgeInsetsDirectional.fromSTEB(
                ThemeConstants.paddingL,
                ThemeConstants.paddingM,
                ThemeConstants.paddingL,
                context.bottomSafePadding + 12,
              ),
              decoration: AppDecorations.card(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: context.cs.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: AppButton(
                label: context.translate(LanguageLabelKeys.signUp),
                height: context.screenHeight * 0.062,
                isLoading: state is SignUpLoading,
                onPressed: () => _registerFormKey.currentState?.submit(),
              ),
            );
          },
        ),
        body: BlocConsumer<SignUpCubit, SignUpState>(
          listener: (context, state) {
            if (state is SignUpLoaded) {
              AppSnackBar.show(
                context: context,
                message: context.translate(LanguageLabelKeys.accountCreated),
                type: SnackBarType.success,
              );
              AppNavigator.pushReplacementNamed(context, RouteNames.login);
            } else if (state is SignUpError) {
              AppSnackBar.show(
                context: context,
                message: state.message,
                type: SnackBarType.error,
              );
            }
          },
          builder: (context, state) {
            return RegisterForm(
              key: _registerFormKey,
              onRegister:
                  ({
                    required name,
                    required mobile,
                    required password,
                    required confirmPassword,
                    required email,
                    required dob,
                    profileImagePath,
                    nationalIdImagePath,
                    drivingLicenseImagePath,
                    required bonusType,
                    required bonusPercentage,
                    bonusMinAmount,
                    bonusMaxAmount,
                    required returnBonusType,
                    returnBonusPercentage,
                    returnBonusMinAmount,
                    returnBonusMaxAmount,
                    countryId,
                    countryCode,
                    zoneId,
                  }) => context.read<SignUpCubit>().register(
                    name: name,
                    mobile: mobile,
                    password: password,
                    confirmPassword: confirmPassword,
                    email: email,
                    dob: dob,
                    profileImagePath: profileImagePath,
                    nationalIdImagePath: nationalIdImagePath,
                    drivingLicenseImagePath: drivingLicenseImagePath,
                    bonusType: bonusType,
                    bonusPercentage: bonusPercentage,
                    bonusMinAmount: bonusMinAmount,
                    bonusMaxAmount: bonusMaxAmount,
                    returnBonusType: returnBonusType,
                    returnBonusPercentage: returnBonusPercentage,
                    returnBonusMinAmount: returnBonusMinAmount,
                    returnBonusMaxAmount: returnBonusMaxAmount,
                    countryId: countryId,
                    countryCode: countryCode,
                    zoneId: zoneId,
                  ),
            );
          },
        ),
      ),
    );
  }
}
