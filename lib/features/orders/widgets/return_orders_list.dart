import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/core/routes/route_names.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import '../models/return_order_model.dart';
import 'package:deliveryboy/core/constants/navigation_service.dart';
import 'order_list_view.dart';
import 'return_order_card.dart';

class ReturnOrdersList extends StatelessWidget {
  final List<ReturnRequestData> orders;
  final bool isLoadingMore;
  final bool hasMore;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;

  const ReturnOrdersList({
    super.key,
    required this.orders,
    required this.isLoadingMore,
    required this.hasMore,
    required this.scrollController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return OrderListView<ReturnRequestData>(
      items: orders,
      isLoadingMore: isLoadingMore,
      hasMore: hasMore,
      scrollController: scrollController,
      onRefresh: onRefresh,
      physics: const AlwaysScrollableScrollPhysics(),
      emptyImagePath: AssetsConstants.noOrderFound,
      emptyTitle: context.translate(LanguageLabelKeys.noReturnRequests),
      emptySubtitle: context.translate(LanguageLabelKeys.noReturnRequestsDesc),
      itemBuilder: (context, order, index) => ReturnOrderCard(
        order: order,
        onTap: () => AppNavigator.pushNamed(
          context,
          RouteNames.returnOrderDetail,
          arguments: order.id,
        ),
      ),
    );
  }
}
