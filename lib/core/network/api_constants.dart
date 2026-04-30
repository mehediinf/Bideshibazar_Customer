import 'package:flutter/foundation.dart';

// lib/core/network/api_constants.dart

class ApiConstants {
  // Base URLs
  static const String baseUrl = 'https://dev.bideshibazar.com/api/';
  static const String imageBaseUrl = 'https://dev.bideshibazar.com/';
  static const String baseUrlWithoutApi = 'https://dev.bideshibazar.com/';

  // static const String baseUrl = 'https://bideshibazar.com/api/';
  // static const String imageBaseUrl = 'https://bideshibazar.com/';
  // static const String baseUrlWithoutApi = 'https://bideshibazar.com/';

  // Update endpoints
  static const String versionEndpoint = 'version-info';
  static const String updateCheckUrl = '${baseUrl}version-info';

  // Auth Endpoints
  static const String register = 'auth/register';
  static const String login = 'auth/login';
  static const String googleLogin = 'auth/google-login';
  static const String sendEmailOtp = 'auth/register/email/send-otp';
  static const String sendPhoneOtp = 'auth/register/send-otp';

  static const String forgotPassword = 'auth/forgot-password';
  static const String resetPassword = 'auth/reset-password';
  static const String findMyAccount = 'auth/find-my-account';

  // OTP Endpoints
  static const String verifyEmailOtp = 'auth/register/email/verify-otp';
  static const String verifyPhoneOtp = 'auth/register/verify-otp';

  // User Endpoints
  static const String updateProfile = 'user/update/profile';
  static const String dashboard = 'user/dashboard';
  static const String saveDeliveryAddress = 'user/save/delivery-address';

  // Product Endpoints
  static const String categories = 'categories';
  static const String homeCategories = 'home/categories';
  static const String allProducts = 'all/products';
  static const String productDetails = 'product/'; // + id
  static const String search = 'search';
  static const String availableShops = 'available/shops';
  static const String productsBySellers = 'products/by-sellers';

  // Offer Endpoints
  static const String offers = 'offers';

  // Blog Endpoints
  static const String blogPosts = 'blog/posts';

  // Cart Endpoints
  static const String addToCart = 'user/add-to-cart';
  static const String viewCart = 'user/view-cart';
  static const String updateCart = 'user/update-cart/'; // + cartItemId
  static const String removeCart = 'user/remove-cart/'; // + cartItemId

  // Cart Endpoints (Guest)
  static const String addToCartGuest = 'add-to-cart';
  static const String viewCartGuest = 'view-cart';
  static const String updateCartGuest = 'update-cart/'; // + cartItemId
  static const String removeCartGuest = 'remove-cart/'; // + cartItemId

  // Wishlist Endpoints
  static const String addToWishlist = 'user/add-to-wishlist';
  static const String getWishlist = 'user/wishlist';
  static const String removeWishlist = 'user/remove-wishlist/'; // + id

  // Store Endpoints
  static const String stores = 'stores';
  static const String storeDetails = 'store/'; // + id
  static const String shops = 'shops';

  // Order Endpoints
  static const String placeOrder = 'user/place-order';
  static const String deliveryDetails = 'user/delivery/details/'; // + id

  // Checkout Endpoints
  static const String verifyAddressInside =
      'user/verify-delivery-address/inside';
  static const String verifyAddressOutside =
      'user/verify-delivery-address/outside';
  static const String placeOrderInside = 'user/place/order/inside';
  static const String placeOrderOutside = 'user/place/order/outside';

  // Other
  static const String submitComplaint = 'user/submit/complaint';
  static const String complaintCategories = 'user/complaints/categories';
  static const String complaintEligibleOrders =
      'user/complaints/eligible-orders';
  static const String complaints = 'user/complaints';

  // Google Maps
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // Helper method to get full image URL with proper encoding
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      debugPrint('Empty image path');
      return '';
    }

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      debugPrint('Full image URL: $imagePath');
      return Uri.encodeFull(imagePath);
    }

    // Construct full URL
    String fullUrl;

    if (imagePath.startsWith('uploads/')) {
      fullUrl = '$imageBaseUrl$imagePath';
    } else if (imagePath.startsWith('/uploads/')) {
      fullUrl = '$imageBaseUrl${imagePath.substring(1)}';
    } else {
      fullUrl = '${imageBaseUrl}uploads/$imagePath';
    }
    final encodedUrl = Uri.encodeFull(fullUrl);

    debugPrint('Constructed image URL: $encodedUrl');
    return encodedUrl;
  }

  // Timeouts
  static const int apiTimeoutSeconds = 10;
  static const int connectionTimeoutSeconds = 15;

  // Headers
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
