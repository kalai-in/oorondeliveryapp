import 'package:deliveryboy/commons/cubit/base_async_cubit.dart';
import 'package:deliveryboy/features/orders/repositories/order_repository.dart';

typedef OrderLiveTrackingState = AsyncState<()>;
typedef OrderLiveTrackingInitial = AsyncInitial<()>;
typedef OrderStatusUpdating = AsyncLoading<()>;
typedef OrderLiveTrackingLoaded = AsyncLoaded<()>;
typedef OrderLiveTrackingError = AsyncError<()>;

/// Pushes the delivery boy's live latitude/longitude for an in-progress order.
class OrderLiveTrackingCubit extends BaseAsyncCubit<()> {
  final OrderRepository _repository;

  OrderLiveTrackingCubit({OrderRepository? repository})
    : _repository = repository ?? OrderRepository();

  /// Sends the current [latitude]/[longitude] for [orderId] with its [orderStatus].
  Future<void> orderLiveTracking({
    required String orderId,
    required String orderStatus,
    required String latitude,
    required String longitude,
  }) => run(() async {
    await _repository.orderLiveTracking(
      orderId: orderId,
      orderStatus: orderStatus,
      latitude: latitude,
      longitude: longitude,
    );
    return ();
  });
}
