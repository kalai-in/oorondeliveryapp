import 'package:deliveryboy/commons/cubit/connectivity_cubit.dart';
import 'package:deliveryboy/commons/utils/pagination_scroll_controller.dart';
import 'package:deliveryboy/commons/widgets/app_date_range_picker.dart';
import 'package:deliveryboy/commons/widgets/app_no_internet_widget.dart';
import 'package:deliveryboy/commons/widgets/app_scaffold.dart';
import 'package:deliveryboy/commons/widgets/custom_app_bar.dart';
import 'package:deliveryboy/commons/widgets/empty_state_widget.dart';
import 'package:deliveryboy/features/orders/widgets/order_skeletons.dart';
import 'package:deliveryboy/core/constants/assets_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/features/orders/cubit/return_order_status_list_filter_cubit.dart';
import 'package:deliveryboy/features/orders/widgets/return_orders_filter.dart';
import 'package:deliveryboy/features/orders/widgets/return_orders_list.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:deliveryboy/utils/extensions/string_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:deliveryboy/commons/cubit/base_pagination_cubit.dart';
import '../cubit/return_order_cubit.dart';
import '../models/return_order_model.dart';

/// List screen for return orders with status and date-range filters.
class ReturnOrdersScreen extends StatefulWidget {
  const ReturnOrdersScreen({super.key});

  @override
  State<ReturnOrdersScreen> createState() => _ReturnOrdersScreenState();
}

class _ReturnOrdersScreenState extends State<ReturnOrdersScreen> {
  late final ReturnOrderCubit _returnOrderCubit;
  final _searchController = TextEditingController();
  late final PaginationScrollController _scrollController;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _returnOrderCubit = ReturnOrderCubit();
    _returnOrderCubit.loadOrders();
    _scrollController = PaginationScrollController(
      onLoadMore: () => _returnOrderCubit.loadMore(),
    );
    context
        .read<ReturnOrderStatusListFilterCubit>()
        .returnOrderStatusesFilter();
  }

  @override
  void dispose() {
    _returnOrderCubit.close();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final range = await showAppDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange:
          _returnOrderCubit.startDate != null &&
              _returnOrderCubit.endDate != null
          ? DateTimeRange(
              start: DateTime.parse(_returnOrderCubit.startDate!),
              end: DateTime.parse(_returnOrderCubit.endDate!),
            )
          : null,
    );
    if (range != null && mounted) {
      _returnOrderCubit.updateFilters(
        status: _returnOrderCubit.selectedStatus,
        search: _searchController.text.trim(),
        startDate: range.start.toApiDateString(),
        endDate: range.end.toApiDateString(),
      );
    }
  }

  void _onStatusChanged(String status) {
    _returnOrderCubit.updateFilters(
      status: status,
      search: _searchController.text.trim(),
      startDate: _returnOrderCubit.startDate,
      endDate: _returnOrderCubit.endDate,
    );
  }

  void _onSearchSubmit(String value) {
    _returnOrderCubit.updateFilters(
      status: _returnOrderCubit.selectedStatus,
      search: value.trim(),
      startDate: _returnOrderCubit.startDate,
      endDate: _returnOrderCubit.endDate,
    );
  }

  void _clearFilters() {
    _searchController.clear();
    _returnOrderCubit.clearFilters();
  }

  void _startSearch() => setState(() => _isSearching = true);

  void _cancelSearch() {
    setState(() => _isSearching = false);
    _searchController.clear();
    _onSearchSubmit('');
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ConnectivityCubit, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivityConnected) {
          context
              .read<ReturnOrderStatusListFilterCubit>()
              .returnOrderStatusesFilter();
          _returnOrderCubit.loadOrders();
        }
      },
      builder: (context, connectivityState) {
        final isOffline = connectivityState is ConnectivityDisconnected;
        return BlocProvider.value(
          value: _returnOrderCubit,
          child: AppScaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: CustomAppBar(
              title: context.translate(LanguageLabelKeys.returnDelivery),
              showBackButton: false,
              isSearching: _isSearching,
              searchController: _searchController,
              onSearchChanged: _onSearchSubmit,
              onSearchStart: _startSearch,
              onSearchCancel: _cancelSearch,
              searchHint: context.translate(
                LanguageLabelKeys.searchReturnOrders,
              ),
              // Status chips would sit above an empty body while offline.
              bottom: isOffline
                  ? null
                  : PreferredSize(
                      preferredSize: const Size.fromHeight(48),
                      child: ReturnStatusChips(
                        onStatusChanged: _onStatusChanged,
                      ),
                    ),
              actions: [
                ReturnDateFilterActions(
                  cubit: _returnOrderCubit,
                  onPickDate: _pickDateRange,
                  onClear: _clearFilters,
                ),
              ],
            ),
            // Offline state lives in the body so the app bar stays available.
            body: isOffline
                ? AppNoInternetFullScreen(
                    embedded: true,
                    onRetry: () => _returnOrderCubit.loadOrders(),
                  )
                : BlocBuilder<
                    ReturnOrderCubit,
                    PaginationState<ReturnRequestData>
                  >(
                    builder: (context, state) {
                      if (state is PaginationLoading<ReturnRequestData>) {
                        return const OrderListSkeleton(
                          variant: OrderSkeletonVariant.returns,
                        );
                      }
                      if (state is PaginationError<ReturnRequestData>) {
                        return EmptyStateWidget(
                          imagePath: AssetsConstants.noOrderFound,
                          title: state.message,
                          subtitle: context.translate(
                            LanguageLabelKeys.pullDownToRefresh,
                          ),
                          onRetry: _returnOrderCubit.loadOrders,
                        );
                      }
                      if (state is PaginationLoaded<ReturnRequestData>) {
                        return ReturnOrdersList(
                          orders: state.data,
                          isLoadingMore: state.isFetchingMore,
                          hasMore: state.hasMore,
                          scrollController: _scrollController.controller,
                          onRefresh: _returnOrderCubit.loadOrders,
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
          ),
        );
      },
    );
  }
}
