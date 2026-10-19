class PlacedOrder {
  final String orderId;
  final String details;
  final int total;
  final String status;

  PlacedOrder(this.orderId, this.details, this.total, this.status);

  factory PlacedOrder.fromJson(Map<String, dynamic> j) => PlacedOrder(
        '${j['order_id']}',
        '${j['item_details']}',
        int.tryParse('${j['total_price']}') ?? 0,
        '${j['status']}',
      );
}