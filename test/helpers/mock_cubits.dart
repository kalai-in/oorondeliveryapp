import 'package:bloc_test/bloc_test.dart';
import 'package:deliveryboy/commons/cubit/countries_cubit.dart';
import 'package:deliveryboy/commons/cubit/country_settings_cubit.dart';
import 'package:deliveryboy/commons/cubit/settings_cubit.dart';
import 'package:deliveryboy/commons/cubit/zones_cubit.dart';
import 'package:deliveryboy/commons/cubit/connectivity_cubit.dart';
import 'package:deliveryboy/features/home/cubit/dashboard_cubit.dart';
import 'package:deliveryboy/features/home/cubit/delivery_boy_status_cubit.dart';
import 'package:deliveryboy/features/profile/cubit/profile_detail_cubit.dart';
import 'package:deliveryboy/features/auth/cubit/forgot_password_cubit.dart';
import 'package:deliveryboy/features/auth/cubit/sign_in_cubit.dart';
import 'package:deliveryboy/features/auth/cubit/sign_up_cubit.dart';

class MockSignInCubit extends MockCubit<SignInState> implements SignInCubit {}

class MockSignUpCubit extends MockCubit<SignUpState> implements SignUpCubit {}

class MockForgotPasswordCubit extends MockCubit<ForgotPasswordState>
    implements ForgotPasswordCubit {}

class MockCountrySettingsCubit extends MockCubit<CountrySettingsState>
    implements CountrySettingsCubit {}

class MockCountriesCubit extends MockCubit<CountriesState>
    implements CountriesCubit {}

class MockZonesCubit extends MockCubit<ZonesState> implements ZonesCubit {}

class MockConnectivityCubit extends MockCubit<ConnectivityState>
    implements ConnectivityCubit {}

class MockSettingsCubit extends MockCubit<SettingsState>
    implements SettingsCubit {}

class MockDashboardCubit extends MockCubit<DashboardState>
    implements DashboardCubit {}

class MockDeliveryBoyStatusCubit extends MockCubit<DeliveryBoyStatusState>
    implements DeliveryBoyStatusCubit {}

class MockProfileDetailCubit extends MockCubit<ProfileDetailState>
    implements ProfileDetailCubit {}
