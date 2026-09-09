import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/constants/navigation_service.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/core/routes/route_names.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import '../models/ecommerce_order_model.dart';
import 'ecommerce_order_card.dart';
import 'order_list_view.dart';

class EcommerceOrderList extends StatelessWidget {
  final List<EcommerceOrderDataModel> orders;
  final bool isLoadingMore;
  final bool hasMore;
  final ScrollController scrollController;
  final Future<void> Function() onRefresh;

  const EcommerceOrderList({
    super.key,
    required this.orders,
    required this.isLoadingMore,
    required this.hasMore,
    required this.scrollController,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return OrderListView<EcommerceOrderDataModel>(
      items: orders,
      isLoadingMore: isLoadingMore,
      hasMore: hasMore,
      scrollController: scrollController,
      onRefresh: onRefresh,
      emptyImagePath: AssetsConstants.noOrderFound,
      emptyTitle: context.translate(LanguageLabelKeys.noOrdersFound),
      emptySubtitle: context.translate(LanguageLabelKeys.noOrdersYet),
      itemBuilder: (context, order, index) => EcommerceOrderCard(
        order: order,
        onTap: () => AppNavigator.pushNamed(
          context,
          RouteNames.ecommerceOrderDetail,
          arguments: order.id?.toString() ?? '',
        ),
      ),
    );
  }
}
