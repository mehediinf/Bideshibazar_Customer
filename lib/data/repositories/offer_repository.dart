// lib/data/repositories/offer_repository.dart
// Add this debug logging to see what the API returns

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/offer_model.dart';
import '../../core/network/api_constants.dart';

class OfferRepository {
  Future<OfferResponse> fetchOffers() async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.offers}');

      debugPrint('═══════════════════════════════════════');
      debugPrint('📤 Fetching Offers');
      debugPrint('URL: $url');
      debugPrint('═══════════════════════════════════════');

      final response = await http.get(url);

      debugPrint('═══════════════════════════════════════');
      debugPrint('📥 Offers Response');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('═══════════════════════════════════════');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Debug: Print first product structure if available
        if (jsonData['offers'] != null && (jsonData['offers'] as List).isNotEmpty) {
          final firstOffer = (jsonData['offers'] as List).first;
          if (firstOffer['products'] != null && (firstOffer['products'] as List).isNotEmpty) {
            final firstProduct = (firstOffer['products'] as List).first;
            debugPrint('═══════════════════════════════════════');
            debugPrint('📦 First Product Structure:');
            debugPrint(json.encode(firstProduct));
            debugPrint('Available keys: ${firstProduct.keys.toList()}');
            debugPrint('═══════════════════════════════════════');
          }
        }

        return OfferResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to fetch offers: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error fetching offers: $e');
      rethrow;
    }
  }
}