// lib/data/models/response/login_response.dart

class LoginResponse {
  final User user;
  final String token;

  LoginResponse({
    required this.user,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      user: User.fromJson(json['user'] ?? {}),
      token: json['token']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
    };
  }
}

class User {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String phone;
  final String? image;
  final String? address;
  final String status;
  final String? fcmToken;
  final String? googleId;
  final String? facebookId;
  final String? appleId;
  final int? sellerId;
  final String ipAddress;
  final String fingerprint;
  final String? otpCode;
  final String? otpExpiresAt;
  final int verified;
  final String? deletedAt;
  final String createdAt;
  final String updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    required this.phone,
    this.image,
    this.address,
    required this.status,
    this.fcmToken,
    this.googleId,
    this.facebookId,
    this.appleId,
    this.sellerId,
    required this.ipAddress,
    required this.fingerprint,
    this.otpCode,
    this.otpExpiresAt,
    required this.verified,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      emailVerifiedAt: json['email_verified_at']?.toString(),
      phone: json['phone']?.toString() ?? '',
      image: json['image']?.toString(),
      address: json['address']?.toString(),
      status: json['status']?.toString() ?? 'active',
      fcmToken: json['fcm_token']?.toString(),
      googleId: json['google_id']?.toString(),
      facebookId: json['facebook_id']?.toString(),
      appleId: json['apple_id']?.toString(),
      sellerId: _parseNullableInt(json['seller_id']),
      ipAddress: json['ip_address']?.toString() ?? '',
      fingerprint: json['fingerprint']?.toString() ?? '',
      otpCode: json['otp_code']?.toString(),
      otpExpiresAt: json['otp_expires_at']?.toString(),
      verified: _parseInt(json['verified']) ?? 0,
      deletedAt: json['deleted_at']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'email_verified_at': emailVerifiedAt,
      'phone': phone,
      'image': image,
      'address': address,
      'status': status,
      'fcm_token': fcmToken,
      'google_id': googleId,
      'facebook_id': facebookId,
      'apple_id': appleId,
      'seller_id': sellerId,
      'ip_address': ipAddress,
      'fingerprint': fingerprint,
      'otp_code': otpCode,
      'otp_expires_at': otpExpiresAt,
      'verified': verified,
      'deleted_at': deletedAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is double) return value.toInt();
    if (value is bool) return value ? 1 : 0;
    return null;
  }

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      if (value.isEmpty) return null;
      return int.tryParse(value);
    }
    if (value is double) return value.toInt();
    return null;
  }
}