class SurgeCharges {
  String? label;
  double? charge;
  bool? isRefundable;

  SurgeCharges({this.label, this.charge, this.isRefundable});

  SurgeCharges.fromJson(Map<String, dynamic> json) {
    label = json['label'] ?? "";
    charge = double.tryParse(json['charge']?.toString() ?? '0') ?? 0.0;
    isRefundable = json['is_refundable'] == true || json['is_refundable'] == 1;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['label'] = label;
    data['charge'] = charge;
    data['is_refundable'] = isRefundable;
    return data;
  }
}
