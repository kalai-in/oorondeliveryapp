import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/features/orders/cubit/return_order_status_list_filter_cubit.dart';
import 'package:deliveryboy/utils/extensions/context_extensions.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:deliveryboy/commons/cubit/base_pagination_cubit.dart';
import '../cubit/return_order_cubit.dart';
import '../models/return_order_model.dart';
import 'order_date_filter_row.dart';
import 'status_filter_chips.dart';

class ReturnStatusChips extends StatelessWidget {
  final ValueChanged<String> onStatusChanged;
  const ReturnStatusChips({super.key, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
      ReturnOrderStatusListFilterCubit,
      ReturnOrderStatusListFilterState
    >(
      builder: (context, filterState) {
        if (filterState is! ReturnOrderStatusListFilterLoaded) {
          return ColoredBox(
            color: context.cs.surface,
            child: const SizedBox(height: 48, width: double.infinity),
          );
        }
        return BlocBuilder<
          ReturnOrderCubit,
          PaginationState<ReturnRequestData>
        >(
          builder: (context, _) => StatusFilterChips(
            statuses: filterState.data,
            selectedId: context.read<ReturnOrderCubit>().selectedStatus,
            onStatusChanged: onStatusChanged,
            height: 48,
          ),
        );
      },
    );
  }
}

class ReturnDateFilterActions extends StatelessWidget {
  final ReturnOrderCubit cubit;
  final VoidCallback onPickDate;
  final VoidCallback onClear;

  const ReturnDateFilterActions({
    super.key,
    required this.cubit,
    required this.onPickDate,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReturnOrderCubit, PaginationState<ReturnRequestData>>(
      builder: (context, _) {
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
