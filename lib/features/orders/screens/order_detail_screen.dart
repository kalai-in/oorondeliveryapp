import 'package:deliveryboy/commons/cubit/connectivity_cubit.dart';
import 'package:deliveryboy/commons/widgets/app_scaffold.dart';
import 'package:deliveryboy/commons/widgets/custom_app_bar.dart';
import 'package:deliveryboy/commons/widgets/empty_state_widget.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/constants/navigation_service.dart';
import 'package:deliveryboy/core/constants/theme_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/core/routes/route_names.dart';
import 'package:deliveryboy/features/chat/models/chat_message.dart';
import 'package:deliveryboy/features/chat/services/chat_conversation_resolver.dart';
import 'package:deliveryboy/features/orders/widgets/order_action_buttons.dart'
    show openOrderTracking;
import 'package:deliveryboy/features/orders/widgets/order_billing_card.dart';
import 'package:deliveryboy/features/orders/widgets/order_appbar_title.dart';
import 'package:deliveryboy/features/orders/widgets/order_items_card.dart';
import 'package:deliveryboy/features/orders/widgets/order_note_card.dart';
import 'package:deliveryboy/features/orders/widgets/pickup_delivery_card.dart';
import 'package:deliveryboy/utils/extensions/string_extensions.dart';
import 'package:deliveryboy/features/orders/widgets/order_status_sheet.dart';
import 'package:deliveryboy/features/orders/widgets/order_timeline_card.dart';
import 'package:deliveryboy/core/theme/app_spacing.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:deliveryboy/utils/extensions/size_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/order_detail_cubit.dart';
import '../models/order_detail_model.dart';
import 'package:deliveryboy/features/orders/widgets/order_skeletons.dart';

/// Detail screen for a single quick order, keyed by the ID passed as route args.
class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final orderId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    return BlocProvider(
      create: (_) => OrderDetailCubit()..loadOrder(orderId),
      child: const _OrderDetailView(),
    );
  }
}

class _OrderDetailView extends StatelessWidget {
  const _OrderDetailView();

  @override
  Widget build(BuildContext context) {
    // No full-screen offline gate here: the OrderDetailError branch below
    // already renders an app bar + Retry, and its message comes from
    // ApiException (connectionError -> "no internet connection"). The one thing
    // it lacked was recovering by itself, hence this listener.
    return BlocListener<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivityConnected) {
          final orderId =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          context.read<OrderDetailCubit>().loadOrder(orderId);
        }
      },
      child: AppScaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        applyBottomInset: false,
        body: BlocBuilder<OrderDetailCubit, OrderDetailState>(
          builder: (context, state) {
            if (state is OrderDetailLoading) {
              return AppScaffold(
                appBar: CustomAppBar(
                  title: context.translate(LanguageLabelKeys.orderDetail),
                ),
                body: const OrderDetailSkeleton(),
              );
            }
            if (state is OrderDetailError) {
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
                    final orderId =
                        ModalRoute.of(context)?.settings.arguments as String? ??
                        '';
                    context.read<OrderDetailCubit>().loadOrder(orderId);
                  },
                ),
              );
            }
            if (state is OrderDetailLoaded) {
              return _OrderDetailBody(detail: state.data);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _OrderDetailBody extends StatelessWidget {
  final OrderDetailData detail;
  const _OrderDetailBody({required this.detail});

  static const _hiddenStatuses = ['1', '2', '7', '8', '9'];
  bool _hideUpdateStatusButton(String? activeStatus) =>
      _hiddenStatuses.contains(activeStatus);

  @override
  Widget build(BuildContext context) {
    final order = detail.order;
    final items = detail.orderItems ?? [];
    final bottomPad = context.bottomSafePadding;
    final symbol = order?.currency ?? "";

    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      applyBottomInset: false,
      extendBody: false,
      appBar: CustomAppBar(
        titleWidget: OrderAppBarTitle(
          statusLabel: order?.orderStatusName ?? order?.statusName ?? '—',
          idLine: order?.orderNumber?.toString() ?? '—',
        ),
      ),
      body: RefreshIndicator(
        color: context.cs.primary,
        onRefresh: () => context.read<OrderDetailCubit>().loadOrder(
          detail.order?.orderId?.toString() ?? '',
        ),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsetsDirectional.fromSTEB(ThemeConstants.paddingL, ThemeConstants.paddingL, ThemeConstants.paddingL, bottomPad),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  PickupDeliveryCard(
                    pickupName: order?.storeInfo?.storeName,
                    pickupAddress: order?.storeInfo?.formattedAddress,
                    pickupPhone: order?.storeInfo?.mobile,
                    pickupLatitude: order?.storeInfo?.latitude,
                    pickupLongitude: order?.storeInfo?.longitude,
                    deliveryName: order?.address?.name ?? "",
                    deliveryAddress: order?.address?.address,
                    deliveryPhone: order?.address?.mobile ?? order?.userMobile,
                    deliveryAlternatePhone: order?.address?.alternateMobile,
                    deliveryLatitude: order?.address?.latitude,
                    deliveryLongitude: order?.address?.longitude,
                    onDeliveryChatTap: order?.isDeliveryBoyChatVisible == true
                        ? () async {
                            final orderId =
                                order?.orderId?.toString() ??
                                order?.id?.toString() ??
                                '';
                            final conversationId =
                                await resolveOrderConversationId(orderId);
                            if (!context.mounted) return;
                            AppNavigator.pushNamed(
                              context,
                              RouteNames.chat,
                              arguments: ChatScreenArgs(
                                chatType: ChatType.deliveryBoyChat,
                                recipientName:
                                    order?.userName ??
                                    context.translate(
                                      LanguageLabelKeys.customer,
                                    ),
                                recipientId: order?.userId ?? 0,
                                orderId: orderId,
                                conversationId: conversationId,
                              ),
                            );
                          }
                        : null,
                  ),
                  if (order?.orderNote.isNotNullOrEmpty ?? false)
                    OrderNoteCard(note: order!.orderNote!),
                  if (detail.timeline?.isNotEmpty ?? false) ...[
                    OrderTimelineCard(
                      timeline: detail.timeline!,
                      onTrackOrder: order?.activeStatus == 5
                          ? () => openOrderTracking(context, order)
                          : null,
                    ),
                    AppSpacing.h16,
                  ],
                  if (items.isNotEmpty)
                    OrderItemsCard(items: items, symbol: symbol),
                  OrderBillingCard(
                    order: order,
                    detail: detail,
                    symbol: symbol,
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          _hideUpdateStatusButton(order?.activeStatus?.toString())
          ? null
          : OrderStatusActionButton(detail: detail),
    );
  }
}
