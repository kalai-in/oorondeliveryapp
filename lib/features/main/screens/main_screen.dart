import 'dart:io';

import 'package:deliveryboy/commons/widgets/app_scaffold.dart';
import 'package:deliveryboy/core/api/api_parameters.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/local_storage/auth_hive_box.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/core/localization/cubit/language_cubit.dart';
import 'package:deliveryboy/core/services/notification_service.dart';
import 'package:deliveryboy/features/auth/cubit/add_fcm_token_cubit.dart';
import 'package:deliveryboy/features/home/cubit/dashboard_cubit.dart';
import 'package:deliveryboy/features/main/models/bottom_navigation.dart';
import 'package:deliveryboy/features/main/widgets/bottom_navigation.dart';
import 'package:deliveryboy/features/earnings/screens/earnings_screen.dart';
import 'package:deliveryboy/features/orders/cubit/order_cubit.dart';
import 'package:deliveryboy/features/orders/cubit/ecommerce_order_cubit.dart';
import 'package:deliveryboy/features/orders/cubit/return_order_cubit.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/nav_cubit.dart';
import '../../home/screens/dashboard_screen.dart';
import '../../orders/screens/orders_screen.dart';
import '../../profile/screens/profile_screen.dart';

/// Root screen hosting the bottom-navigated Home/Orders/Earnings/Profile tabs.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const _screens = [
    HomeScreen(),
    OrdersScreen(),
    EarningsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _syncMissingFcmToken();
  }

  /// Login sends the FCM token along with the credentials, but that token can
  /// still be blank at that point (Firebase hadn't handed one out yet, or the
  /// fetch failed offline). In that case the session has no token registered
  /// server-side, and nothing else retries until the token rotates or the app
  /// is relaunched — so retry it here, once the user lands post-login.
  Future<void> _syncMissingFcmToken() async {
    final service = NotificationService.instance;
    if (AuthHiveBox.instance.fcmToken.isNotEmpty) return;
    final token = await service.getToken();
    if (token == null || token.isEmpty || !mounted) return;
    // Re-checked after the await: the service's own token sync may have landed
    // while Firebase was still resolving, which leaves nothing to do here.
    if (AuthHiveBox.instance.fcmToken.isNotEmpty) return;
    // Loses the race against the service's sync of the same token — that call
    // registers it, so firing a second identical one would be pure duplication.
    if (!service.beginTokenRegistration()) return;
    try {
      final cubit = context.read<AddFcmTokenCubit>();
      await cubit.addFcmToken(
        fcmToken: token,
        platform: Platform.isAndroid
            ? ApiParameters.android
            : ApiParameters.ios,
      );
      // Cached only on success: leaving the box blank after a failed call is
      // what makes NotificationService retry the registration on next launch.
      if (cubit.state is AddFcmTokenLoaded) {
        await AuthHiveBox.instance.setFcmToken(token);
      }
    } finally {
      service.endTokenRegistration();
    }
  }

  void _reloadOnLanguageChange() {
    context.read<DashboardCubit>().getDashboard();
    context.read<OrderCubit>().loadOrders();
    context.read<EcommerceOrderCubit>().loadOrders();
    context.read<ReturnOrderCubit>().loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    final navItems = [
      BottomNavItem(
        label: context.translate(LanguageLabelKeys.home),
        activeIconPath: AssetsConstants.homeActiveIcon,
        inactiveIconPath: AssetsConstants.homeInActiveIcon,
      ),
      BottomNavItem(
        label: context.translate(LanguageLabelKeys.myDelivery),
        activeIconPath: AssetsConstants.orderActiveIcon,
        inactiveIconPath: AssetsConstants.orderInActiveIcon,
      ),
      BottomNavItem(
        label: context.translate(LanguageLabelKeys.earnings),
        activeIconPath: AssetsConstants.walletActiveIcon,
        inactiveIconPath: AssetsConstants.walletInActiveIcon,
      ),
      BottomNavItem(
        label: context.translate(LanguageLabelKeys.profile),
        activeIconPath: AssetsConstants.profileActiveIcon,
        inactiveIconPath: AssetsConstants.profileInActiveIcon,
      ),
    ];

    // No connectivity gate here on purpose: each tab renders its own
    // no-internet state, which keeps the bottom bar reachable while offline and
    // preserves per-tab state (scroll position, filters, selected tab) instead
    // of tearing the whole IndexedStack down and rebuilding it on reconnect.
    return BlocProvider(
      create: (_) => NavCubit(),
      child: BlocListener<LanguageCubit, LanguageState>(
        listenWhen: (previous, current) =>
            previous is LanguageLoaded &&
            current is LanguageLoaded &&
            previous.selectedId != current.selectedId,
        listener: (context, state) => _reloadOnLanguageChange(),
        child: BlocBuilder<NavCubit, NavState>(
          builder: (context, state) {
            return PopScope(
              canPop: state.currentIndex == 0,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                context.read<NavCubit>().changeTab(0);
              },
              child: AppScaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                applyBottomInset: false,
                body: IndexedStack(
                  index: state.currentIndex,
                  children: _screens,
                ),
                bottomNavigationBar: BottomNavBar(
                  currentIndex: state.currentIndex,
                  onTap: context.read<NavCubit>().changeTab,
                  items: navItems,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
