// lib/core/utils/wishlist_manager.dart

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:developer' as developer;
import '../../data/models/wishlist_model.dart';
import '../network/api_service.dart';
import '../utils/shared_prefs_helper.dart';

class WishlistManager extends ChangeNotifier {
  static final WishlistManager _instance = WishlistManager._internal();
  factory WishlistManager() => _instance;
  WishlistManager._internal();

  final ApiService _apiService = ApiService();
  final List<WishlistItem> _wishlistItems = [];
  bool _isLoading = false;

  List<WishlistItem> get wishlistItems => List.unmodifiable(_wishlistItems);
  int get wishlistCount => _wishlistItems.length;
  bool get isLoading => _isLoading;

  // Check if product is in wishlist
  bool isInWishlist(int productId) {
    return _wishlistItems.any((item) => item.productId == productId.toString());
  }

  // Get wishlist item by product ID
  WishlistItem? getWishlistItem(int productId) {
    try {
      return _wishlistItems.firstWhere(
            (item) => item.productId == productId.toString(),
      );
    } catch (e) {
      return null;
    }
  }

  // Load wishlist from API
  Future<void> loadWishlist() async {
    try {
      _isLoading = true;
      notifyListeners();

      final token = await SharedPrefsHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        developer.log('❌ No auth token found');
        _wishlistItems.clear();
        _isLoading = false;
        notifyListeners();
        return;
      }

      developer.log('🔄 Loading wishlist...');

      final responseData = await _apiService.getWishlist(token);
      final response = WishlistResponse.fromJson(responseData);

      _wishlistItems.clear();
      _wishlistItems.addAll(response.wishlistItems);
      developer.log('✅ Wishlist loaded: ${_wishlistItems.length} items');
    } catch (e) {
      developer.log('❌ Error loading wishlist: $e');
      _wishlistItems.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle wishlist (add or remove)
  Future<bool> toggleWishlist(BuildContext context, int productId) async {
    try {
      // Check if user is logged in
      final isLoggedIn = await SharedPrefsHelper.isLoggedIn();
      if (!isLoggedIn) {
        _showToast('Please login first to add to wishlist');
        developer.log('⚠️ User not logged in');
        return false;
      }

      final token = await SharedPrefsHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        _showToast('Please login first to add to wishlist');
        return false;
      }

      // Check if product is already in wishlist
      final existingItem = getWishlistItem(productId);

      if (existingItem != null) {
        // Remove from wishlist
        return await removeFromWishlist(context, existingItem.id);
      } else {
        // Add to wishlist
        return await addToWishlist(context, productId);
      }
    } catch (e) {
      developer.log('❌ Error toggling wishlist: $e');
      _showToast('Failed to update wishlist');
      return false;
    }
  }

  // Add to wishlist
  Future<bool> addToWishlist(BuildContext context, int productId) async {
    try {
      final token = await SharedPrefsHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        _showToast('Please login first to add to wishlist');
        return false;
      }

      developer.log('➕ Adding product $productId to wishlist...');

      final responseData = await _apiService.addToWishlist(
        token,
        {'product_id': productId.toString()},
      );

      final response = WishlistResponse.fromJson(responseData);

      _wishlistItems.clear();
      _wishlistItems.addAll(response.wishlistItems);

      _showToast('Added to Wishlist ❤️');
      notifyListeners();
      developer.log('✅ Added to wishlist successfully');
      return true;
    } catch (e) {
      developer.log('❌ Error adding to wishlist: $e');
      _showToast('Failed to add to wishlist');
      return false;
    }
  }

  // Remove from wishlist
  Future<bool> removeFromWishlist(BuildContext context, int wishlistItemId) async {
    try {
      final token = await SharedPrefsHelper.getAuthToken();
      if (token == null || token.isEmpty) {
        _showToast('Please login first');
        return false;
      }

      developer.log('🗑️ Removing wishlist item $wishlistItemId...');

      final responseData = await _apiService.removeFromWishlist(
        token,
        wishlistItemId,
      );

      final response = WishlistResponse.fromJson(responseData);

      _wishlistItems.clear();
      _wishlistItems.addAll(response.wishlistItems);

      _showToast('Removed from Wishlist 💔');
      notifyListeners();
      developer.log('✅ Removed from wishlist successfully');
      return true;
    } catch (e) {
      developer.log('❌ Error removing from wishlist: $e');
      _showToast('Failed to remove from wishlist');
      return false;
    }
  }

  // Clear all wishlist (used during logout)
  void clear() {
    _wishlistItems.clear();
    notifyListeners();
  }

  // Show toast message
  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}