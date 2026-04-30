// lib/data/models/address_model.dart

class AddressModel {
  String fullAddress;
  String road;
  String house;
  String room;
  String postCode;
  String city;
  double? lat;
  double? lon;

  AddressModel({
    required this.fullAddress,
    required this.road,
    required this.house,
    required this.room,
    required this.postCode,
    required this.city,
    this.lat,
    this.lon,
  });

  // Get formatted details for display
  String getFormattedDetails() {
    List<String> parts = [];

    if (road.isNotEmpty) parts.add('Road: $road');
    if (house.isNotEmpty) parts.add('House: $house');
    if (room.isNotEmpty) parts.add('Room: $room');
    if (postCode.isNotEmpty) parts.add('Post: $postCode');
    if (city.isNotEmpty) parts.add('City: $city');

    return parts.join(', ');
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'fullAddress': fullAddress,
      'road': road,
      'house': house,
      'room': room,
      'postCode': postCode,
      'city': city,
      'lat': lat,
      'lon': lon,
    };
  }

  // Create from JSON
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      fullAddress: json['fullAddress'] ?? '',
      road: json['road'] ?? '',
      house: json['house'] ?? '',
      room: json['room'] ?? '',
      postCode: json['postCode'] ?? '',
      city: json['city'] ?? '',
      lat: json['lat'],
      lon: json['lon'],
    );
  }

  // Copy with method for easy updates
  AddressModel copyWith({
    String? fullAddress,
    String? road,
    String? house,
    String? room,
    String? postCode,
    String? city,
    double? lat,
    double? lon,
  }) {
    return AddressModel(
      fullAddress: fullAddress ?? this.fullAddress,
      road: road ?? this.road,
      house: house ?? this.house,
      room: room ?? this.room,
      postCode: postCode ?? this.postCode,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
    );
  }
}