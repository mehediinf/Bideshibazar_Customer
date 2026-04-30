// lib/core/services/checkout_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/shared_prefs_helper.dart';

class CheckoutApiService {
  static const String baseUrl = 'https://dev.bideshibazar.com/api';

  static Future<String?> _getAuthToken() async {
    return await SharedPrefsHelper.getToken();
  }

  static Future<Map<String, dynamic>> verifyAddressInside({
    required String name,
    required String email,
    required String mobile,
    required String address,
    required String postcode,
    required String city,
    required double lat,
    required double lon,
    required double subtotal,
    required String deliveryType,
  }) async {
    try {
      final token = await _getAuthToken();

      // Build query parameters
      final queryParams = {
        'name': name,
        'email': email,
        'mobile': mobile,
        'address': address,
        'postcode': postcode,
        'city': city,
        'lat': lat.toString(),
        'lon': lon.toString(),
        'subtotal': subtotal.toString(),
        'delivery_type': deliveryType,
      };

      // Build URL with query parameters
      final uri = Uri.parse('$baseUrl/user/verify-delivery-address/inside')
          .replace(queryParameters: queryParams);

      print('Verify Address Inside URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to verify address: ${response.statusCode}');
      }
    } catch (e) {
      print(' Verify address inside error: $e');
      throw Exception('Verify address error: $e');
    }
  }

  static Future<Map<String, dynamic>> verifyAddressOutside({
    required String name,
    required String email,
    required String mobile,
    required String address,
    required String postcode,
    required String city,
    required double lat,
    required double lon,
    required double subtotal,
  }) async {
    try {
      final token = await _getAuthToken();

      // Build query parameters
      final queryParams = {
        'name': name,
        'email': email,
        'mobile': mobile,
        'address': address,
        'postcode': postcode,
        'city': city,
        'lat': lat.toString(),
        'lon': lon.toString(),
        'subtotal': subtotal.toString(),
      };

      // Build URL with query parameters
      final uri = Uri.parse('$baseUrl/user/verify-delivery-address/outside')
          .replace(queryParameters: queryParams);

      print('Verify Address Outside URL: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to verify address: ${response.statusCode}');
      }
    } catch (e) {
      print(' Verify address outside error: $e');
      throw Exception('Verify address error: $e');
    }
  }

  // Place order inside Wien (POST request)
  static Future<Map<String, dynamic>> placeOrderInside({
    required String name,
    required String email,
    required String mobile,
    required String city,
    required String postCode,
    required String address,
    required double lat,
    required double lon,
    required String deliveryType,
    required double subtotal,
    required double deliveryChargeCustomer,
    required bool isDeliveryChargeFree,
    String? houseNo,
    String? orderNotes,
    String? scheduledTime,
  }) async {
    try {
      final token = await _getAuthToken();

      final body = {
        'name': name,
        'email': email,
        'mobile': mobile,
        'city': city,
        'postcode': postCode,
        'address': address,
        'house_no': houseNo,
        'lat': lat,
        'lon': lon,
        'delivery_type': deliveryType,
        'is_delivery_charge_free': isDeliveryChargeFree,
        'delivery_charge_customer': deliveryChargeCustomer,
        'subtotal': subtotal,
        if (orderNotes != null && orderNotes.isNotEmpty) 'order_notes': orderNotes,
        if (scheduledTime != null && scheduledTime.isNotEmpty) 'scheduled_time': scheduledTime,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/user/place/order/inside'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to place order: ${response.statusCode}');
      }
    } catch (e) {
      print(' Place order inside error: $e');
      throw Exception('Place order error: $e');
    }
  }

  // Place order outside Wien
  static Future<Map<String, dynamic>> placeOrderOutside({
    required String name,
    required String email,
    required String mobile,
    required String city,
    required String postCode,
    required String address,
    required double lat,
    required double lon,
    required String deliveryType,
    required double subtotal,
    required double shippingCharge,
    required double deliveryChargeCustomer,
    required bool isDeliveryChargeFree,
    required bool isOutsideWien,
    required double grandTotal,
    String? orderNotes,
    String? scheduledTime,
  }) async {
    try {
      final token = await _getAuthToken();

      final body = {
        'name': name,
        'email': email,
        'mobile': mobile,
        'city': city,
        'post_code': postCode,
        'address': address,
        'lat': lat,
        'lon': lon,
        'delivery_type': deliveryType,
        'subtotal': subtotal,
        'shipping_charge': shippingCharge,
        'delivery_charge_customer': deliveryChargeCustomer,
        'is_delivery_charge_free': isDeliveryChargeFree,
        'is_outside_wien': isOutsideWien,
        'grand_total': grandTotal,
        if (orderNotes != null && orderNotes.isNotEmpty) 'order_notes': orderNotes,
        if (scheduledTime != null && scheduledTime.isNotEmpty) 'scheduled_time': scheduledTime,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/user/place/order/outside'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return responseData;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['message'] ?? 'Failed to place order: ${response.statusCode}');
      }
    } catch (e) {
      print('Place order outside error: $e');
      throw Exception('Place order error: $e');
    }
  }
}