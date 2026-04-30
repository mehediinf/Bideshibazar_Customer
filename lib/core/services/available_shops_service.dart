// lib/core/services/available_shops_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';
import '../network/api_constants.dart';

class AvailableShopsService {
  static final String baseUrl = 'https://bideshibazar.com/';

  /// Fetch available shops based on address
  static Future<Map<String, dynamic>> fetchAvailableShops({
    required String street,
    required String city,
    required String postcode,
    required double lat,
    required double lon,
  }) async {
    try {
      final url = Uri.parse(baseUrl).resolve('api/available/shops');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'street': street,
          'city': city,
          'postcode': postcode,
          'lat': lat,
          'lon': lon,
        }),
      );

      debugPrint('Available Shops API Response: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to fetch available shops: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching available shops: $e');
      rethrow;
    }
  }
}



