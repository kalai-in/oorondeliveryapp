import 'package:deliveryboy/commons/cubit/connectivity_cubit.dart';
import 'package:deliveryboy/commons/widgets/app_scaffold.dart';
import 'package:deliveryboy/commons/widgets/custom_app_bar.dart';
import 'package:deliveryboy/commons/widgets/empty_state_widget.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/features/orders/widgets/order_skeletons.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/constants/navigation_service.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/core/routes/route_names.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/features/chat/models/chat_message.dart';
import 'package:deliveryboy/features/chat/services/chat_conversation_resolver.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:deliveryboy/utils/extensions/size_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/ecommerce_order_detail_cubit.dart';
import '../models/ecommerce_order_model.dart';
import '../widgets/order_appbar_title.dart';
import '../widgets/ecommerce_order_detail_items_card.dart';
import '../widgets/ecommerce_order_customer_info_card.dart';
import '../widgets/ecommerce_order_billing_card.dart';
import '../widgets/pickup_delivery_card.dart';
import '../widgets/order_timeline_card.dart';
import '../widgets/ecommerce_order_status_sheet.dart';

/// Detail screen for a single ecommerce order, keyed by the ID passed as route args.
class EcommerceOrderDetailScreen extends StatefulWidget {
  const EcommerceOrderDetailScreen({super.key});

  @override
  State<EcommerceOrderDetailScreen> createState() =>
      _EcommerceOrderDetailScreenState();
}

class _EcommerceOrderDetailScreenState
    extends State<EcommerceOrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final orderItemId =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return BlocProvider(
      create: (_) => EcommerceOrderDetailCubit()..loadOrderDetail(orderItemId),
      child: const _EcommerceOrderDetailView(),
    );
  }
}

class _EcommerceOrderDetailView extends StatelessWidget {
  const _EcommerceOrderDetailView();

  @override
  Widget build(BuildContext context) {
    // No full-screen offline gate here: the error branch below already renders
    // an app bar + Retry with ApiException's "no internet connection" message.
    // This listener just adds recovery without a manual tap.
    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivityConnected) {
          final orderItemId =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          context.read<EcommerceOrderDetailCubit>().loadOrderDetail(
            orderItemId,
          );
        }
      },
      child: AppScaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        applyBottomInset: false,
        body: BlocBuilder<EcommerceOrderDetailCubit, EcommerceOrderDetailState>(
          builder: (context, state) {
            if (state is EcommerceOrderDetailLoading) {
              return AppScaffold(
                appBar: CustomAppBar(
                  title: context.translate(LanguageLabelKeys.orderDetail),
                ),
                body: const OrderDetailSkeleton(),
              );
            }
            if (state is EcommerceOrderDetailError) {
              return AppScaffold(
                appBar: CustomAppBar(
                  title: context.translate(LanguageLabelKeys.orderDetail),
                  backgroundColor: context.cs.primary,
                  foregroundColor: context.cs.onPrimary,
                ),
                body: EmptyStateWidget(
                  imagePath: AssetsConstants.noOrderFound,
                  title: state.message,
                  subtitle: context.translate(
                    LanguageLabelKeys.pullDownToRefresh,
                  ),
                  onRetry: () {
                    final orderItemId =
                        ModalRoute.of(context)?.settings.arguments as String? ??
                        '';
                    context.read<EcommerceOrderDetailCubit>().loadOrderDetail(
                      orderItemId,
                    );
                  },
                ),
              );
            }
            if (state is EcommerceOrderDetailLoaded) {
              return _EcommerceOrderDetailBody(order: state.data);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _EcommerceOrderDetailBody extends StatelessWidget {
  final EcommerceOrderDataModel order;
  const _EcommerceOrderDetailBody({required this.order});

  static const _hiddenStatuses = [1, 2, 3, 7, 8];
  bool get _hideUpdateStatusButton =>
      _hiddenStatuses.contains(order.activeStatus);

  @override
  Widget build(BuildContext context) {
    final symbol = order.currency ?? '';
    final timeline = order.timeline ?? [];
    final bottomPad = context.bottomSafePadding;

    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      applyBottomInset: false,
      extendBody: false,
      appBar: CustomAppBar(
        titleWidget: OrderAppBarTitle(
          statusLabel: order.orderItemStatus ?? '—',
          idLine: order.orderNumber?.toString() ?? '—',
        ),
      ),
      body: RefreshIndicator(
        color: context.cs.primary,
        onRefresh: () => context
            .read<EcommerceOrderDetailCubit>()
            .loadOrderDetail((order.id)?.toString() ?? ''),
        child: ListView(
          padding: EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingL, ThemeConstants.paddingL, bottomPad),
          children: [
            PickupDeliveryCard(
              pickupName: order.storeInfo?.storeName ?? order.storeName,
              pickupAddress: order.storeInfo?.formattedAddress,
              pickupPhone: order.storeInfo?.mobile,
              pickupLatitude: order.storeInfo?.latitude,
              pickupLongitude: order.storeInfo?.longitude,
              deliveryName: order.addressInfo?.name,
              deliveryAddress: order.addressInfo?.address ?? order.orderAddress,
              deliveryPhone: order.addressInfo?.mobile ?? order.orderMobile,
              deliveryAlternatePhone: order.addressInfo?.alternateMobile,
              deliveryLatitude: order.addressInfo?.latitude,
              deliveryLongitude: order.addressInfo?.longitude,
              onDeliveryChatTap: order.isDeliveryBoyChatVisible == true
                  ? () async {
                      final orderId =
                          order.orderId?.toString() ??
                          order.id?.toString() ??
                          '';
                      final orderItemId = order.id?.toString();
                      final conversationId = await resolveOrderConversationId(
                        orderId,
                        orderItemId: orderItemId,
                      );
                      if (!context.mounted) return;
                      AppNavigator.pushNamed(
                        context,
                        RouteNames.chat,
                        arguments: ChatScreenArgs(
                          chatType: ChatType.deliveryBoyChat,
                          recipientName:
                              order.addressInfo?.name ??
                              context.translate(LanguageLabelKeys.customer),
                          recipientId: order.userId ?? 0,
                          orderId: orderId,
                          conversationId: conversationId,
                        ),
                      );
                    }
                  : null,
            ),
            if (timeline.isNotEmpty) ...[
              AppSpacing.h12,
              OrderTimelineCard(timeline: timeline),
            ],
            AppSpacing.h12,
            EcommerceOrderDetailItemsCard(order: order, symbol: symbol),
            AppSpacing.h12,
            EcommerceOrderBillingCard(order: order, symbol: symbol),
            AppSpacing.h12,
            EcommerceOrderCustomerInfoCard(order: order),
          ],
        ),
      ),
      bottomNavigationBar: _hideUpdateStatusButton
          ? null
          : EcommerceOrderStatusActionButton(order: order),
    );
  }
}
