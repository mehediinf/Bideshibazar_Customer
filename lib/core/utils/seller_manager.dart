import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';

class SellerManager {
  static final SellerManager _instance = SellerManager._internal();
  factory SellerManager() => _instance;
  SellerManager._internal();

  final Logger _logger = Logger();
  static const String _keySellerIds = 'seller_ids';

  List<int> _sellerIds = [];
  final List<Function(List<int>)> _listeners = [];
  Function? _onSellerListChanged;

  // ============ GETTERS ============
  List<int> get sellerIds => List.unmodifiable(_sellerIds);

  String get sellerIdsString {
    if (_sellerIds.isEmpty) return '';
    return _sellerIds.join(',');
  }

  // ============ LOAD & SAVE ============
  Future<void> loadSellerIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? json = prefs.getString(_keySellerIds);

      if (json != null && json.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(json);
        _sellerIds = decoded.map((e) => e as int).toList();
        _logger.d('📦 Loaded seller IDs: $_sellerIds');
      } else {
        _sellerIds = [];
      }
    } catch (e) {
      _logger.e('Error loading seller IDs: $e');
      _sellerIds = [];
    }
  }

  Future<void> saveSellerIds(List<int> ids) async {
    try {
      _sellerIds = ids;

      final prefs = await SharedPreferences.getInstance();
      final String json = jsonEncode(ids);
      await prefs.setString(_keySellerIds, json);

      _logger.d('💾 Saved seller IDs: $ids');

      _notifyListeners();
      _notifySellerListChanged();
    } catch (e) {
      _logger.e('Error saving seller IDs: $e');
    }
  }

  Future<void> clearSellerIds() async {
    try {
      _sellerIds = [];

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keySellerIds);

      _logger.d('🧹 Cleared seller IDs');

      _notifyListeners();
      _notifySellerListChanged();
    } catch (e) {
      _logger.e('Error clearing seller IDs: $e');
    }
  }

  // ============ LISTENERS ============
  void addListener(Function(List<int>) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }

  void removeListener(Function(List<int>) listener) {
    _listeners.remove(listener);
  }

  void setOnSellerListChangedListener(Function listener) {
    _onSellerListChanged = listener;
  }

  void removeOnSellerListChangedListener() {
    _onSellerListChanged = null;
  }

  void _notifyListeners() {
    for (var listener in _listeners) {
      try {
        listener(List.from(_sellerIds));
      } catch (e) {
        _logger.e('Listener error: $e');
      }
    }
  }

  void _notifySellerListChanged() {
    try {
      _onSellerListChanged?.call();
    } catch (e) {
      _logger.e('Seller list changed listener error: $e');
    }
  }

  // ============ UTILITY ============
  bool isEmpty() => _sellerIds.isEmpty;

  bool contains(int sellerId) => _sellerIds.contains(sellerId);
}