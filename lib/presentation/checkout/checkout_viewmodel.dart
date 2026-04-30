// lib/presentation/checkout/checkout_viewmodel.dart

import 'package:flutter/material.dart';
import '../../core/services/checkout_api_service.dart';
import '../../core/utils/cart_manager.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../data/models/checkout_model.dart';

class CheckoutViewModel extends ChangeNotifier {
  // Form Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final roomController = TextEditingController();
  final addressController = TextEditingController();
  final orderNotesController = TextEditingController();

  // State
  String _countryCode = '+43';
  String _deliveryType = 'express';
  String? _scheduledTime;
  bool _isVerified = false;
  bool _isVerifying = false;
  bool _isPlacingOrder = false;

  // Address Data
  String _savedAddress = '';
  String _savedCity = '';
  String _savedPostcode = '';
  String _savedRoad = '';
  double _savedLat = 0.0;
  double _savedLon = 0.0;

  // Verify Response
  VerifyAddressResponse? _verifyResponse;

  // Login Type
  bool _isEmailLogin = true;

  // Getters
  String get countryCode => _countryCode;
  String get deliveryType => _deliveryType;
  String? get scheduledTime => _scheduledTime;
  bool get isVerified => _isVerified;
  bool get isVerifying => _isVerifying;
  bool get isPlacingOrder => _isPlacingOrder;
  String get savedAddress => _savedAddress;
  String get savedCity => _savedCity;
  String get savedPostcode => _savedPostcode;
  double get savedLat => _savedLat;
  double get savedLon => _savedLon;
  VerifyAddressResponse? get verifyResponse => _verifyResponse;
  bool get isEmailLogin => _isEmailLogin;

  // Initialize
  Future<void> initialize() async {
    await _loadUserData();
    await _loadSavedAddress();
  }

  Future<void> _loadUserData() async {
    final name = await SharedPrefsHelper.getUserName() ?? '';
    final email = await SharedPrefsHelper.getUserEmail() ?? '';
    final mobile = await SharedPrefsHelper.getUserMobile() ?? '';

    if (email.isNotEmpty && mobile.isEmpty) {
      _isEmailLogin = true;
    } else if (mobile.isNotEmpty && email.isEmpty) {
      _isEmailLogin = false;
    } else {
      _isEmailLogin = true;
    }

    nameController.text = name;
    emailController.text = email;
    mobileController.text = mobile.replaceAll(_countryCode, '');
    notifyListeners();
  }

  Future<void> _loadSavedAddress() async {
    final address = await SharedPrefsHelper.getSavedAddress();
    if (address != null) {
      _savedAddress = address['address'] ?? address['fullAddress'] ?? '';
      _savedCity = address['city'] ?? '';
      _savedPostcode = address['postcode'] ?? address['postCode'] ?? '';
      _savedRoad = address['road'] ?? '';
      _savedLat = (address['lat'] ?? 0.0).toDouble();
      _savedLon = (address['lon'] ?? 0.0).toDouble();

      if (_savedAddress.isNotEmpty) {
        addressController.text =
        '$_savedAddress\nRoad: $_savedRoad, Post: $_savedPostcode, City: $_savedCity';
      }

      notifyListeners();
    }
  }

  void updateAddress(Map<String, dynamic> addressData) {
    _savedAddress = addressData['address'] ?? addressData['fullAddress'] ?? '';
    _savedCity = addressData['city'] ?? '';
    _savedPostcode = addressData['postcode'] ?? addressData['postCode'] ?? '';
    _savedRoad = addressData['road'] ?? '';
    _savedLat = (addressData['lat'] ?? 0.0).toDouble();
    _savedLon = (addressData['lon'] ?? 0.0).toDouble();

    if (_savedAddress.isNotEmpty) {
      addressController.text =
      '$_savedAddress\nRoad: $_savedRoad, Post: $_savedPostcode, City: $_savedCity';
    } else {
      addressController.text = '';
    }

    _isVerified = false;
    notifyListeners();

    final normalizedAddress = {
      'address': _savedAddress,
      'fullAddress': _savedAddress,
      'city': _savedCity,
      'postcode': _savedPostcode,
      'postCode': _savedPostcode,
      'road': _savedRoad,
      'lat': _savedLat,
      'lon': _savedLon,
    };

    SharedPrefsHelper.saveSavedAddress(normalizedAddress);
  }

  void setDeliveryType(String type) {
    _deliveryType = type;
    _isVerified = false;
    notifyListeners();
  }

  void setScheduledTime(String? time) {
    _scheduledTime = time;
    notifyListeners();
  }

  bool _isViennaCity(String city) {
    final cityLower = city.toLowerCase().trim();
    return cityLower == 'wien' || cityLower == 'vienna';
  }

  // Raw exception কে user-friendly message এ convert করে
  String _parseErrorMessage(dynamic error) {
    final raw = error.toString();

    // HTML response এলে (session expired / not logged in)
    if (raw.contains('<html') ||
        raw.contains('<head') ||
        raw.contains('<style') ||
        raw.contains('<!DOCTYPE') ||
        raw.contains('FormatException') ||
        raw.contains('Unexpected character')) {
      return 'Session expired. Please log in again and try.';
    }

    // Network / connectivity error
    if (raw.contains('SocketException') ||
        raw.contains('Connection refused') ||
        raw.contains('Network is unreachable') ||
        raw.contains('Failed host lookup')) {
      return 'No internet connection. Please check your network and try again.';
    }

    // Timeout
    if (raw.contains('TimeoutException') || raw.contains('timed out')) {
      return 'Request timed out. Please try again.';
    }

    // Server error (500 range)
    if (raw.contains('500') || raw.contains('Internal Server Error')) {
      return 'Server error. Please try again after a few moments.';
    }

    // Unauthorized / 401
    if (raw.contains('401') || raw.contains('Unauthorized')) {
      return 'You are not logged in. Please log in and try again.';
    }

    // Generic fallback — technical details লুকিয়ে সহজ message দেখাও
    return 'Address verification failed. Please try again.';
  }

  Future<String?> verifyAddress(double subtotal) async {
    if (_savedAddress.isEmpty) {
      return 'Please select a delivery address.';
    }

    if (_savedCity.isEmpty) {
      return 'Address is incomplete. Please select again.';
    }

    if (_savedLat == 0.0 || _savedLon == 0.0) {
      return 'Address location is invalid. Please select again.';
    }

    _isVerifying = true;
    _isVerified = false;
    notifyListeners();

    try {
      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final mobile = '$_countryCode${mobileController.text.trim()}';

      Map<String, dynamic> response;

      if (_isViennaCity(_savedCity)) {
        response = await CheckoutApiService.verifyAddressInside(
          name: name,
          email: email,
          mobile: mobile,
          address: _savedAddress,
          postcode: _savedPostcode,
          city: _savedCity,
          lat: _savedLat,
          lon: _savedLon,
          subtotal: subtotal,
          deliveryType: _deliveryType,
        );
      } else {
        response = await CheckoutApiService.verifyAddressOutside(
          name: name,
          email: email,
          mobile: mobile,
          address: _savedAddress,
          postcode: _savedPostcode,
          city: _savedCity,
          lat: _savedLat,
          lon: _savedLon,
          subtotal: subtotal,
        );
      }

      _verifyResponse = VerifyAddressResponse.fromJson(response);
      _isVerified = true;
      _isVerifying = false;
      notifyListeners();
      return null;

    } catch (e) {
      debugPrint('Verification error: $e');
      _isVerifying = false;
      _isVerified = false;
      notifyListeners();

      // User-friendly error message return
      return _parseErrorMessage(e);
    }
  }

  Future<Map<String, dynamic>?> placeOrder(CartManager cartManager) async {
    if (!_isVerified) {
      return {'error': 'Please verify your address first.'};
    }

    _isPlacingOrder = true;
    notifyListeners();

    try {
      final subtotal = cartManager.totalPrice;
      final deliveryCharge = _verifyResponse?.deliveryCharge ?? 0.0;
      final grandTotal = subtotal + deliveryCharge;

      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final mobile = '$_countryCode${mobileController.text.trim()}';
      final orderNotes = orderNotesController.text.trim();
      final houseNo = roomController.text.trim();

      Map<String, dynamic> response;

      if (_isViennaCity(_savedCity)) {
        response = await CheckoutApiService.placeOrderInside(
          name: name,
          email: email,
          mobile: mobile,
          city: _savedCity,
          postCode: _savedPostcode,
          address: _savedAddress,
          lat: _savedLat,
          lon: _savedLon,
          deliveryType: _deliveryType,
          subtotal: subtotal,
          deliveryChargeCustomer: deliveryCharge,
          isDeliveryChargeFree: _verifyResponse?.isDeliveryChargeFree ?? false,
          houseNo: houseNo.isNotEmpty ? houseNo : null,
          orderNotes: orderNotes.isNotEmpty ? orderNotes : null,
          scheduledTime: _deliveryType == 'scheduled' ? _scheduledTime : null,
        );
      } else {
        response = await CheckoutApiService.placeOrderOutside(
          name: name,
          email: email,
          mobile: mobile,
          city: _savedCity,
          postCode: _savedPostcode,
          address: _savedAddress,
          lat: _savedLat,
          lon: _savedLon,
          deliveryType: _deliveryType,
          subtotal: subtotal,
          shippingCharge: deliveryCharge,
          deliveryChargeCustomer: deliveryCharge,
          isDeliveryChargeFree: _verifyResponse?.isDeliveryChargeFree ?? false,
          isOutsideWien: true,
          grandTotal: grandTotal,
          orderNotes: orderNotes.isNotEmpty ? orderNotes : null,
          scheduledTime: _deliveryType == 'scheduled' ? _scheduledTime : null,
        );
      }

      final orderNumber = response['order_number']?.toString() ??
          response['order_id']?.toString() ??
          response['orderId']?.toString() ??
          response['data']?['order_number']?.toString() ??
          response['data']?['order_id']?.toString() ??
          'ORD00089';

      _isPlacingOrder = false;
      notifyListeners();

      await cartManager.clearCart();

      return {
        'success': true,
        'order_number': orderNumber,
        'user_name': name,
        'message': response['message']?.toString() ?? 'Order placed successfully',
      };
    } catch (e) {
      debugPrint('Place order error: $e');
      _isPlacingOrder = false;
      notifyListeners();

      // User-friendly error message return করো
      return {'error': _parseErrorMessage(e)};
    }
  }

  List<String> generateTimeSlots() {
    List<String> slots = [];
    for (int hour = 9; hour <= 21; hour++) {
      slots.add(
          '${hour.toString().padLeft(2, '0')}:00 - ${(hour + 1).toString().padLeft(2, '0')}:00');
    }
    return slots;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    roomController.dispose();
    addressController.dispose();
    orderNotesController.dispose();
    super.dispose();
  }
}