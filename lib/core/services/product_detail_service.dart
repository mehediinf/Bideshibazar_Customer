// lib/core/services/product_detail_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import '../network/api_constants.dart';

class ProductDetailService {
  static const String baseUrl = ApiConstants.baseUrl;

  static Future<Map<String, dynamic>> fetchProductDetails(
    int shopProductId,
  ) async {
    try {
      final url = Uri.parse(baseUrl).resolve('product/$shopProductId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        try {
          final errorData = json.decode(response.body);
          final errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              'Failed to fetch product details';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception(
            'Failed to fetch product details: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchRelatedProducts(
    int shopProductId,
  ) async {
    try {
      final url = Uri.parse(baseUrl).resolve('related/products/$shopProductId');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final relatedProducts = data['related_products'];

        if (relatedProducts is List) {
          return relatedProducts
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }

        return [];
      } else {
        try {
          final errorData = json.decode(response.body);
          final errorMessage =
              errorData['message'] ??
              errorData['error'] ??
              'Failed to fetch related products';
          throw Exception(errorMessage);
        } catch (e) {
          throw Exception(
            'Failed to fetch related products: ${response.statusCode}',
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
