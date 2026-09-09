import 'package:deliveryboy/utils/extensions/num_extensions.dart';

class Timeline {
  int? status;
  String? statusName;
  String? datetime;

  Timeline({this.status, this.statusName, this.datetime});

  Timeline.fromJson(Map<String, dynamic> json) {
    status = toSafeIntOrNull(json['status']);
    statusName = json['status_name']?.toString();
    datetime = json['datetime']?.toString();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['status'] = status;
    data['status_name'] = statusName;
    data['datetime'] = datetime;
    return data;
  }
}
