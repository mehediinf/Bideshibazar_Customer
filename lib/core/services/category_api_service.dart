// lib/core/services/category_api_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/models/category_model.dart';

class CategoryApiService {
  static const String baseUrl = 'https://dev.bideshibazar.com/api';

  Future<CategoryResponse> fetchCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return CategoryResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  Future<Map<String, dynamic>> fetchHomeCategories({
    List<int>? sellerIds,
  }) async {
    try {
      String url = '$baseUrl/home/categories';

      if (sellerIds != null && sellerIds.isNotEmpty) {
        final sellerIdsParam = sellerIds.join(',');
        url += '?seller_ids=$sellerIdsParam';
        debugPrint(
          'Fetching home categories WITH filter: seller_ids=$sellerIdsParam',
        );
      } else {
        debugPrint('Fetching home categories WITHOUT filter (all sellers)');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        debugPrint('Home categories fetched successfully');
        return jsonData;
      } else {
        throw Exception('Failed to load home categories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching home categories: $e');
    }
  }

  Future<Map<String, dynamic>> fetchCategoryProducts({
    required int categoryId,
    List<int>? sellerIds,
  }) async {
    try {
      String url = '$baseUrl/category/$categoryId';

      if (sellerIds != null && sellerIds.isNotEmpty) {
        final sellerIdsParam = sellerIds.join(',');
        url += '?seller_ids=$sellerIdsParam';
        debugPrint(
          'Fetching category $categoryId WITH filter: seller_ids=$sellerIdsParam',
        );
      } else {
        debugPrint('Fetching category $categoryId WITHOUT filter (all sellers)');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        debugPrint('Category products fetched successfully');
        return jsonData;
      } else {
        throw Exception('Failed to load category products: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching category products: $e');
    }
  }
}
