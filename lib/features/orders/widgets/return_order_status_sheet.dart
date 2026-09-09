import 'package:deliveryboy/commons/widgets/app_snack_bar.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/features/orders/cubit/return_order_detail_cubit.dart';
import 'package:deliveryboy/features/orders/cubit/return_order_status_list_cubit.dart';
import 'package:deliveryboy/features/orders/cubit/return_request_order_status_update_cubit.dart';
import 'package:deliveryboy/features/orders/models/return_order_model.dart'
    show ReturnOrderStatus, ReturnRequestData;
import 'package:deliveryboy/features/orders/widgets/order_status_slide_bar.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Single button that advances the return request to the next status in the
/// sequence (Out for Pickup -> Received from Customer -> Return to Store).
/// No picker is shown — only the active next status can be applied.
class ReturnOrderStatusActionButton extends StatelessWidget {
  final ReturnRequestData detail;
  const ReturnOrderStatusActionButton({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => ReturnOrderStatusListCubit()..loadStatuses(),
        ),
        BlocProvider(create: (_) => ReturnRequestOrderStatusUpdateCubit()),
      ],
      child: _ReturnOrderStatusAction(detail: detail),
    );
  }
}

class _ReturnOrderStatusAction extends StatelessWidget {
  final ReturnRequestData detail;
  const _ReturnOrderStatusAction({required this.detail});

  @override
  Widget build(BuildContext context) {
    final returnRequestId = detail.id?.toString() ?? '';
    return BlocListener<
      ReturnRequestOrderStatusUpdateCubit,
      ReturnRequestOrderStatusUpdateState
    >(
      listener: (ctx, state) {
        if (state is ReturnRequestOrderStatusUpdateLoaded) {
          context.read<ReturnOrderDetailCubit>().loadDetail(
            returnRequestId.toString(),
          );
          AppSnackBar.show(
            context: context,
            message: context.translate(LanguageLabelKeys.orderStatusUpdated),
            type: SnackBarType.success,
          );
        } else if (state is ReturnRequestOrderStatusUpdateError) {
          AppSnackBar.show(
            context: context,
            message: state.message,
            type: SnackBarType.error,
          );
        }
      },
      child: BlocBuilder<ReturnOrderStatusListCubit, ReturnOrderStatusListState>(
        builder: (ctx, listState) {
          if (listState is! ReturnOrderStatusListLoaded) {
            return const SizedBox.shrink();
          }
          if (detail.returnStatusEnum == ReturnOrderStatus.returnToSeller ||
              detail.returnStatusEnum == ReturnOrderStatus.rejected) {
            return const SizedBox.shrink();
          }

          final statuses = listState.data;
          final currentIndex = statuses.indexWhere(
            (s) => s.id == detail.status?.toString(),
          );
          final nextIndex = currentIndex + 1;
          if (nextIndex >= statuses.length) return const SizedBox.shrink();

          final next = statuses[nextIndex];
          return BlocBuilder<
            ReturnRequestOrderStatusUpdateCubit,
            ReturnRequestOrderStatusUpdateState
          >(
            builder: (ctx2, updateState) {
              final isUpdating =
                  updateState is ReturnRequestOrderStatusUpdating;
              return OrderStatusSlideBar(
                label:
                    '${context.translate(LanguageLabelKeys.markAs)} ${next.statusName ?? ''}',
                isLoading: isUpdating,
                onConfirm: isUpdating
                    ? null
                    : () => ctx2
                          .read<ReturnRequestOrderStatusUpdateCubit>()
                          .updateReturnRequestOrderStatus(
                            returnRequestId: returnRequestId.toString(),
                            orderStatus: next.id ?? '',
                          ),
              );
            },
          );
        },
      ),
    );
  }
}
