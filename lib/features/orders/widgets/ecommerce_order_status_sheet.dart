import 'package:deliveryboy/commons/widgets/app_snack_bar.dart';
import 'package:deliveryboy/core/constants/app_constants.dart';
import 'package:deliveryboy/core/localization/language_label_key.dart';
import 'package:deliveryboy/features/orders/cubit/ecommerce_order_detail_cubit.dart';
import 'package:deliveryboy/features/orders/cubit/order_status_list_cubit.dart';
import 'package:deliveryboy/features/orders/cubit/order_status_update_cubit.dart';
import 'package:deliveryboy/features/orders/models/ecommerce_order_model.dart';
import 'package:deliveryboy/features/orders/models/order_status.dart';
import 'package:deliveryboy/features/orders/widgets/delivery_otp_bottom_sheet.dart';
import 'package:deliveryboy/features/orders/widgets/order_status_slide_bar.dart';
import 'package:deliveryboy/utils/extensions/localization_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Single button that advances the ecommerce order straight to the next
/// status returned by the order_statuses API (channel: ecommerce). No picker
/// is shown — only the active next status can be applied.
class EcommerceOrderStatusActionButton extends StatelessWidget {
  final EcommerceOrderDataModel order;
  const EcommerceOrderStatusActionButton({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              OrderStatusListCubit()
                ..loadStatuses(channel: AppConstants.ecommerce),
        ),
        BlocProvider(create: (_) => OrderStatusUpdateCubit()),
      ],
      child: _EcommerceOrderStatusAction(order: order),
    );
  }
}

class _EcommerceOrderStatusAction extends StatelessWidget {
  final EcommerceOrderDataModel order;
  const _EcommerceOrderStatusAction({required this.order});

  @override
  Widget build(BuildContext context) {
    final orderId = order.id?.toString() ?? '';
    return BlocListener<OrderStatusUpdateCubit, OrderStatusUpdateState>(
      listener: (ctx, state) {
        if (state is OrderStatusUpdateLoaded) {
          context.read<EcommerceOrderDetailCubit>().loadOrderDetail(orderId);
          AppSnackBar.show(
            context: context,
            message: context.translate(LanguageLabelKeys.orderStatusUpdated),
            type: SnackBarType.success,
          );
        } else if (state is OrderStatusUpdateError) {
          AppSnackBar.show(
            context: context,
            message: state.message,
            type: SnackBarType.error,
          );
        }
      },
      child: BlocBuilder<OrderStatusListCubit, OrderStatusListState>(
        builder: (ctx, listState) {
          if (listState is! OrderStatusListLoaded) {
            return const SizedBox.shrink();
          }

          final statuses = listState.data;
          final currentIndex = statuses.indexWhere(
            (s) => s.id == order.activeStatus?.toString(),
          );
          final nextIndex = currentIndex + 1;
          if (nextIndex >= statuses.length) return const SizedBox.shrink();

          final next = statuses[nextIndex];
          final expectedOtp = order.otp;
          // OTP is only asked for when the backend actually issued one — a null
          // or 0 OTP means delivery can be confirmed without verification.
          final requiresOtp =
              OrderStatus.fromValue(next.id) == OrderStatus.delivered &&
              expectedOtp != null &&
              expectedOtp != 0;
          return BlocBuilder<OrderStatusUpdateCubit, OrderStatusUpdateState>(
            builder: (ctx2, updateState) {
              final isUpdating = updateState is OrderStatusUpdating;
              return OrderStatusSlideBar(
                label:
                    '${context.translate(LanguageLabelKeys.markAs)} ${next.statusName ?? ''}',
                isLoading: isUpdating,
                onConfirm: isUpdating
                    ? null
                    : () async {
                        String? verifiedOtp;
                        if (requiresOtp) {
                          verifiedOtp = await showDeliveryOtpBottomSheet(
                            context: ctx2,
                            expectedOtp: expectedOtp,
                          );
                          if (verifiedOtp == null) return;
                        }
                        if (!ctx2.mounted) return;
                        ctx2.read<OrderStatusUpdateCubit>().updateStatus(
                          orderId: orderId,
                          orderStatus: next.id ?? '',
                          otp: verifiedOtp,
                        );
                      },
              );
            },
          );
        },
      ),
    );
  }
}
