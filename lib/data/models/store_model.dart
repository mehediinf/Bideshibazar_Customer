// lib/data/models/store_model.dart

import '../../core/network/api_constants.dart';

class StoreModel {
  final int id;
  final String? code;
  final String? balance;
  final String name;
  final String? uidNumber;
  final String? steuerNummer;
  final String? gisaZahl;
  final String shopName;
  final String? username;
  final String email;
  final String? emailVerifiedAt;
  final String? productsType;
  final int? countryId;
  final int? districtId;
  final int? cityId;
  final String? postCode;
  final String? tradeLicence;
  final String? tinBinInfo;
  final String? venueId;
  final String? image;
  final String? storeImage;
  final String? banner;
  final String phone;
  final String address;
  final String? description;
  final String? facebook;
  final String? instagram;
  final String? whatsapp;
  final String status;
  final int? sortOrder;
  final int userId;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;
  final int productsCount;

  StoreModel({
    required this.id,
    this.code,
    this.balance,
    required this.name,
    this.uidNumber,
    this.steuerNummer,
    this.gisaZahl,
    required this.shopName,
    this.username,
    required this.email,
    this.emailVerifiedAt,
    this.productsType,
    this.countryId,
    this.districtId,
    this.cityId,
    this.postCode,
    this.tradeLicence,
    this.tinBinInfo,
    this.venueId,
    this.image,
    this.storeImage,
    this.banner,
    required this.phone,
    required this.address,
    this.description,
    this.facebook,
    this.instagram,
    this.whatsapp,
    required this.status,
    this.sortOrder,
    required this.userId,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.productsCount,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) {
    try {
      return StoreModel(
        id: _parseInt(json['id']) ?? 0,
        code: json['code']?.toString(),
        balance: json['balance']?.toString(),
        name: json['name']?.toString() ?? 'Unknown',
        uidNumber: json['uid_number']?.toString(),
        steuerNummer: json['steuer_nummer']?.toString(),
        gisaZahl: json['gisa_zahl']?.toString(),
        shopName: json['shop_name']?.toString() ?? 'Unknown Shop',
        username: json['username']?.toString(),
        email: json['email']?.toString() ?? '',
        emailVerifiedAt: json['email_verified_at']?.toString(),
        productsType: json['products_type']?.toString(),
        countryId: _parseInt(json['country_id']),
        districtId: _parseInt(json['district_id']),
        cityId: _parseInt(json['city_id']),
        postCode: json['post_code']?.toString(),
        tradeLicence: json['trade_licence']?.toString(),
        tinBinInfo: json['tin_bin_info']?.toString(),
        venueId: json['venue_id']?.toString(),
        image: json['image']?.toString(),
        storeImage: json['store_image']?.toString(),
        banner: json['banner']?.toString(),
        phone: json['phone']?.toString() ?? '',
        address: json['address']?.toString() ?? 'No address',
        description: json['description']?.toString(),
        facebook: json['facebook']?.toString(),
        instagram: json['instagram']?.toString(),
        whatsapp: json['whatsapp']?.toString(),
        status: json['status']?.toString() ?? 'inactive',
        sortOrder: _parseInt(json['sort_order']),
        userId: _parseInt(json['user_id']) ?? 0,
        deletedAt: json['deleted_at']?.toString(),
        createdAt: json['created_at']?.toString() ?? '',
        updatedAt: json['updated_at']?.toString() ?? '',
        productsCount: _parseInt(json['products_count']) ?? 0,
      );
    } catch (e, stackTrace) {
      // If parsing fails, throw with details
      throw Exception('Error parsing StoreModel: $e\nStackTrace: $stackTrace\nJSON: $json');
    }
  }

  // Helper method to safely parse int from dynamic
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  String? get fullStoreImageUrl {
    if (storeImage == null || storeImage!.isEmpty) return null;
    if (storeImage!.startsWith('http')) return storeImage;
    return '${ApiConstants.imageBaseUrl}uploads/seller/store_image/$storeImage';
  }

  String get establishedYear {
    try {
      if (createdAt.isEmpty) return '2024';
      final date = DateTime.parse(createdAt);
      return date.year.toString();
    } catch (e) {
      return '2024';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'balance': balance,
      'name': name,
      'uid_number': uidNumber,
      'steuer_nummer': steuerNummer,
      'gisa_zahl': gisaZahl,
      'shop_name': shopName,
      'username': username,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'products_type': productsType,
      'country_id': countryId,
      'district_id': districtId,
      'city_id': cityId,
      'post_code': postCode,
      'trade_licence': tradeLicence,
      'tin_bin_info': tinBinInfo,
      'venue_id': venueId,
      'image': image,
      'store_image': storeImage,
      'banner': banner,
      'phone': phone,
      'address': address,
      'description': description,
      'facebook': facebook,
      'instagram': instagram,
      'whatsapp': whatsapp,
      'status': status,
      'sort_order': sortOrder,
      'user_id': userId,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'products_count': productsCount,
    };
  }
}