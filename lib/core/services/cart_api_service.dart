// lib/core/services/cart_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../network/api_constants.dart';
import '../utils/shared_prefs_helper.dart';

class CartApiService {
  // Add product to cart
  static Future<Map<String, dynamic>> addToCart({
    required int productId,
  }) async {
    try {
      final token = await SharedPrefsHelper.getToken();

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.addToCart}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'product_id': productId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to add to cart');
      }
    } catch (e) {
      debugPrint(' Error adding to cart: $e');
      rethrow;
    }
  }

  // Get cart items
  static Future<Map<String, dynamic>> viewCart() async {
    try {
      final token = await SharedPrefsHelper.getToken();

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.viewCart}');

      debugPrint(' Fetching cart items...');

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(' Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to fetch cart');
      }
    } catch (e) {
      debugPrint(' Error fetching cart: $e');
      rethrow;
    }
  }

  // Update cart item quantity
  static Future<Map<String, dynamic>> updateCart({
    required int cartItemId,
    required int quantity,
  }) async {
    try {
      final token = await SharedPrefsHelper.getToken();

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.updateCart}$cartItemId'
      );

      debugPrint(' Updating cart item: ID = $cartItemId, Quantity = $quantity');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'quantity': quantity,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update cart');
      }
    } catch (e) {
      debugPrint(' Error updating cart: $e');
      rethrow;
    }
  }

  // Remove item from cart
  static Future<Map<String, dynamic>> removeFromCart({
    required int cartItemId,
  }) async {
    try {
      final token = await SharedPrefsHelper.getToken();

      if (token == null) {
        throw Exception('User not authenticated');
      }

      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.removeCart}$cartItemId'
      );

      debugPrint(' Removing cart item: ID = $cartItemId');

      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint(' Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to remove from cart');
      }
    } catch (e) {
      debugPrint(' Error removing from cart: $e');
      rethrow;
    }
  }
}



