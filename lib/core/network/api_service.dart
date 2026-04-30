// lib/core/network/api_service.dart
import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import 'api_constants.dart';
import '../utils/login_device_info.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  final Logger _logger = Logger();

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          _logger.d('REQUEST[${options.method}] => ${options.uri}');
          _logger.d('Headers: ${options.headers}');
          _logger.d('Body: ${options.data}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          _logger.i(
            'RESPONSE[${response.statusCode}] => ${response.requestOptions.uri}',
          );
          _logger.d('Data: ${response.data}');
          return handler.next(response);
        },
        onError: (error, handler) {
          _logger.e(
            'ERROR[${error.response?.statusCode}] => ${error.requestOptions.uri}',
          );
          _logger.e('Message: ${error.message}');
          _logger.e('Response: ${error.response?.data}');
          return handler.next(error);
        },
      ),
    );
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.register, data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.login, data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> googleLogin(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.googleLogin, data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> getCategories({String? sellerIds}) async {
    final response = await _dio.get(
      ApiConstants.categories,
      queryParameters: sellerIds != null ? {'seller_ids': sellerIds} : null,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getHomeCategories({String? sellerIds}) async {
    final response = await _dio.get(
      ApiConstants.homeCategories,
      queryParameters: sellerIds != null ? {'seller_ids': sellerIds} : null,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getProductsByCategoryId(
    int categoryId, {
    String? sellerIds,
  }) async {
    final response = await _dio.get(
      'category/$categoryId',
      queryParameters: sellerIds != null ? {'seller_ids': sellerIds} : null,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getProductsBySubcategory(
    int subcategoryId, {
    String? sellerIds,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.categories}$subcategoryId/',
      queryParameters: sellerIds != null ? {'seller_ids': sellerIds} : null,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> searchProducts(
    String keyword, {
    String? sellerIds,
  }) async {
    final response = await _dio.get(
      ApiConstants.search,
      queryParameters: {
        'keyword': keyword,
        if (sellerIds != null) 'seller_ids': sellerIds,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getAvailableShops(
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(ApiConstants.availableShops, data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> getStores() async {
    final response = await _dio.get(ApiConstants.stores);
    return response.data;
  }

  Future<Map<String, dynamic>> getStoreDetails(int storeId) async {
    final response = await _dio.get('${ApiConstants.storeDetails}$storeId');
    return response.data;
  }

  Future<Map<String, dynamic>> getProductsByStore(int storeId) async {
    final response = await _dio.get('store/$storeId');
    return response.data;
  }

  Future<Map<String, dynamic>> addToCart(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(
      ApiConstants.addToCart,
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> viewCart(String token) async {
    final response = await _dio.get(
      ApiConstants.viewCart,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateCartItem(
    String token,
    int cartItemId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(
      '${ApiConstants.updateCart}$cartItemId',
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> removeCartItem(
    String token,
    int cartItemId,
  ) async {
    final response = await _dio.delete(
      '${ApiConstants.removeCart}$cartItemId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> addToCartGuest(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.addToCartGuest, data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> viewCartGuest(String guestId) async {
    final response = await _dio.get(
      ApiConstants.viewCartGuest,
      queryParameters: {'guest_id': guestId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> updateCartItemGuest(
    int cartItemId,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(
      '${ApiConstants.updateCartGuest}$cartItemId',
      data: body,
    );
    return response.data;
  }

  Future<Map<String, dynamic>> removeCartItemGuest(
    int cartItemId,
    String guestId,
  ) async {
    final response = await _dio.delete(
      '${ApiConstants.removeCartGuest}$cartItemId',
      queryParameters: {'guest_id': guestId},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> addToWishlist(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(
      ApiConstants.addToWishlist,
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getWishlist(String token) async {
    final response = await _dio.get(
      ApiConstants.getWishlist,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> removeFromWishlist(
    String token,
    int wishlistId,
  ) async {
    final response = await _dio.delete(
      '${ApiConstants.removeWishlist}$wishlistId',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> saveDeliveryAddress(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(
      ApiConstants.saveDeliveryAddress,
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getOffers() async {
    final response = await _dio.get(ApiConstants.offers);
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post(
      ApiConstants.updateProfile,
      data: body,
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    return response.data;
  }

  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  Future<Map<String, dynamic>> forgotPassword(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.forgotPassword, data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> resetPassword(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.resetPassword, data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> sendEmailOtp(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.sendEmailOtp, data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> sendPhoneOtp(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.sendPhoneOtp, data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> verifyEmailOtp(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.verifyEmailOtp, data: body);
    return response.data;
  }

  Future<Map<String, dynamic>> verifyPhoneOtp(Map<String, dynamic> body) async {
    final response = await _dio.post(ApiConstants.verifyPhoneOtp, data: body);
    return response.data;
  }

  // Send Email OTP for Login/Registration
  Future<Map<String, dynamic>> sendEmailOtpForLogin(String email) async {
    try {
      final response = await _dio.post(
        '/auth/register/email/send-otp',
        data: {'email': email},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to send OTP');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Network error. Please try again.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  //Verify Email OTP for Login/Registration
  Future<Map<String, dynamic>> verifyEmailOtpForLogin(
    String email,
    String otp, {
    String? fcmToken,
    LoginDeviceInfo? deviceInfo,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/register/email/verify-otp',
        data: {
          'email': email,
          'otp': otp,
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
          if (deviceInfo != null) ...deviceInfo.toJson(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Verification failed');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Network error. Please try again.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Find Account by Email or Mobile
  Future<Map<String, dynamic>> findAccount(String emailOrMobile) async {
    try {
      final response = await _dio.post(
        '/auth/find-my-account',
        data: {'email_or_mobile': emailOrMobile},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Account not found');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Network error. Please try again.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Send Login OTP
  Future<Map<String, dynamic>> sendLoginOtp(String identifier) async {
    try {
      final response = await _dio.post(
        '/auth/login/send-otp',
        data: {'identifier': identifier},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to send OTP');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Network error. Please try again.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Verify Login OTP
  Future<Map<String, dynamic>> verifyLoginOtp(
    String identifier,
    String otp, {
    String? fcmToken,
    LoginDeviceInfo? deviceInfo,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login/verify-otp',
        data: {
          'identifier': identifier,
          'otp': otp,
          if (fcmToken != null && fcmToken.isNotEmpty) 'fcm_token': fcmToken,
          if (deviceInfo != null) ...deviceInfo.toJson(),
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Verification failed');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Network error. Please try again.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Delete User Account
  Future<Map<String, dynamic>> deleteAccount(String token) async {
    try {
      final response = await _dio.get(
        '/user/delete-account',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(response.data['message'] ?? 'Failed to delete account');
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Network error. Please try again.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // Change Password
  Future<Map<String, dynamic>> changePassword(
    String token,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.post(
        '/user/change-password',
        data: body,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception(
          response.data['message'] ?? 'Failed to change password',
        );
      }
    } on DioException catch (e) {
      if (e.response?.data != null && e.response!.data['message'] != null) {
        throw Exception(e.response!.data['message']);
      }
      throw Exception('Network error. Please try again.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}
