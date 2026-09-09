import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/features/orders/cubit/order_status_list_filter_cubit.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:deliveryboy/commons/cubit/base_pagination_cubit.dart';
import '../cubit/order_cubit.dart';
import '../cubit/ecommerce_order_cubit.dart';
import '../models/order_model.dart';
import '../models/ecommerce_order_model.dart';
import 'order_date_filter_row.dart';
import 'status_filter_chips.dart';

/// Shared status-chip bar for the Quick Order and Ecommerce Order tabs.
/// [isEcommerce] picks which cubit's [selectedStatus] drives the highlighted
/// chip — the two tabs share this one widget but track separate cubits, so
/// the selection must follow whichever tab is active.
class OrderStatusChips extends StatelessWidget {
  final ValueChanged<String> onStatusChanged;
  final bool isEcommerce;
  const OrderStatusChips({
    super.key,
    required this.onStatusChanged,
    this.isEcommerce = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderStatusListFilterCubit, OrderStatusListFilterState>(
      builder: (context, filterState) {
        if (filterState is! OrderStatusListFilterLoaded) {
          return ColoredBox(
            color: context.cs.surface,
            child: const SizedBox(height: 44, width: double.infinity),
          );
        }
        if (isEcommerce) {
          return BlocBuilder<
            EcommerceOrderCubit,
            PaginationState<EcommerceOrderDataModel>
          >(
            builder: (context, _) => StatusFilterChips(
              statuses: filterState.data,
              selectedId: context.read<EcommerceOrderCubit>().selectedStatus,
              onStatusChanged: onStatusChanged,
            ),
          );
        }
        return BlocBuilder<OrderCubit, PaginationState<OrderData>>(
          builder: (context, _) => StatusFilterChips(
            statuses: filterState.data,
            selectedId: context.read<OrderCubit>().selectedStatus,
            onStatusChanged: onStatusChanged,
          ),
        );
      },
    );
  }
}

class DateFilterActions extends StatelessWidget {
  final VoidCallback onPickDate;
  final VoidCallback onClear;
  const DateFilterActions({
    super.key,
    required this.onPickDate,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrderCubit, PaginationState<OrderData>>(
      builder: (context, _) {
        final cubit = context.read<OrderCubit>();
        final hasDate = cubit.startDate != null || cubit.endDate != null;
        return OrderDateFilterRow(
          hasDate: hasDate,
          hasActiveFilters: cubit.hasActiveFilters,
          dateTooltip: hasDate
              ? '${cubit.startDate} → ${cubit.endDate}'
              : context.translate(LanguageLabelKeys.dateRange),
          onPickDate: onPickDate,
          onClear: onClear,
        );
      },
    );
  }
}
