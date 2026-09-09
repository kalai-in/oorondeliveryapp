/// Backend order status codes, shared across normal, ecommerce, and quick
/// order channels — mirrors the mapping documented in [OrderStatusLabels].
/// Ids 1,2,5,6,7,8 are shared by both channels; 3 (processing)/4 (shipped)
/// only occur for ecommerce orders; 9 (preparing)/10 (ready for pickup)/11
/// (pickup) only for quick orders.
enum OrderStatus {
  paymentPending(1),
  received(2),
  processing(3),
  shipped(4),
  outForDelivery(5),
  delivered(6),
  cancelled(7),
  returned(8),
  preparing(9),
  readyForPickup(10),
  pickup(11);

  const OrderStatus(this.id);

  final int id;

  /// String form, matching the `order_statuses` API's `id` field (e.g. `next.id`).
  String get value => id.toString();

  static OrderStatus? fromId(int? id) {
    for (final status in OrderStatus.values) {
      if (status.id == id) return status;
    }
    return null;
  }

  static OrderStatus? fromValue(String? value) =>
      fromId(int.tryParse(value ?? ''));
}
