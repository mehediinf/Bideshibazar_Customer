// lib/data/models/delivery_status_model.dart

class DeliveryStatusModel {
  final DeliveryDetails deliveryDetails;

  DeliveryStatusModel({required this.deliveryDetails});

  factory DeliveryStatusModel.fromJson(Map<String, dynamic> json) {
    return DeliveryStatusModel(
      deliveryDetails: DeliveryDetails.fromJson(json['delivery_details'] ?? {}),
    );
  }
}

class DeliveryDetails {
  final String name;
  final String mobile;
  final String email;
  final String address;
  final String deliveryType;
  final String deliveryPartner;
  final String approxDeliveryTime;
  final String woltOrderId;
  final String trackingUrl;
  final String deliveryPartnerLogo;
  final String status;

  DeliveryDetails({
    required this.name,
    required this.mobile,
    required this.email,
    required this.address,
    required this.deliveryType,
    required this.deliveryPartner,
    required this.approxDeliveryTime,
    required this.woltOrderId,
    required this.trackingUrl,
    required this.deliveryPartnerLogo,
    required this.status,
  });

  factory DeliveryDetails.fromJson(Map<String, dynamic> json) {
    return DeliveryDetails(
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      email: json['email'] ?? '',
      address: json['address'] ?? '',
      deliveryType: json['delivery_type'] ?? '',
      deliveryPartner: json['delivery_partner'] ?? 'Not Found',
      approxDeliveryTime: json['approx_delivery_time'] ?? 'N/A',
      woltOrderId: json['wolt_order_id'] ?? 'N/A',
      trackingUrl: json['tracking_url'] ?? '',
      deliveryPartnerLogo: json['delivery_partner_logo'] ?? '',
      status: json['status'] ?? 'transit',
    );
  }
}


