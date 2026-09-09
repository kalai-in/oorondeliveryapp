class AdditionalCharges {
  String? name;
  double? amount;
  bool? isRefundable;

  AdditionalCharges({this.name, this.amount, this.isRefundable});

  AdditionalCharges.fromJson(Map<String, dynamic> json) {
    name = json['name'] ?? "";
    amount = double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0;
    isRefundable = json['is_refundable'] == true || json['is_refundable'] == 1;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['amount'] = amount;
    data['is_refundable'] = isRefundable;
    return data;
  }
}
