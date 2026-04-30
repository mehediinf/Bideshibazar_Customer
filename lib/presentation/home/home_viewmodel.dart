// lib/presentation/home/home_viewmodel.dart

import 'package:flutter/material.dart';
import '../../data/models/category_model.dart';
import '../../data/models/address_model.dart';
import '../../core/services/category_api_service.dart';
import '../../core/services/available_shops_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/app_error_helper.dart';
import '../../core/utils/wishlist_manager.dart';

class HomeViewModel extends ChangeNotifier {
  int _selectedCategory = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<Subcategory> _subcategories = [];
  final List<Map<String, dynamic>> _subcategoriesWithProducts = [];
  final Map<int, List<Product>> _productsBySubcategory = {};

  // Address management
  AddressModel? _selectedAddress;
  String _displayAddress = "Select address";

  // Available shops data
  List<int> _sellerIds = [];
  Map<String, dynamic>? _availableShopsData;

  final CategoryApiService _apiService = CategoryApiService();
  final WishlistManager _wishlistManager = WishlistManager();

  int get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<Subcategory> get subcategories => _subcategories;
  List<Map<String, dynamic>> get subcategoriesWithProducts =>
      _subcategoriesWithProducts;
  AddressModel? get selectedAddress => _selectedAddress;
  List<int> get sellerIds => _sellerIds;
  Map<String, dynamic>? get availableShopsData => _availableShopsData;

  bool hasSameSelectedAddress(AddressModel address) {
    final current = _selectedAddress;
    if (current == null) return false;

    return current.fullAddress == address.fullAddress &&
        current.road == address.road &&
        current.city == address.city &&
        current.postCode == address.postCode &&
        current.house == address.house &&
        current.room == address.room &&
        current.lat == address.lat &&
        current.lon == address.lon;
  }

  void applySavedAddress(AddressModel address) {
    if (hasSameSelectedAddress(address)) return;

    _selectedAddress = address;
    _displayAddress = address.fullAddress;
    notifyListeners();
  }

  HomeViewModel() {
    initialize();
  }

  Future<void> initialize() async {
    await Future.wait([_loadSelectedAddress(), _loadSellerIds()]);

    // If address exists but no seller IDs, fetch available shops
    if (_selectedAddress != null && _sellerIds.isEmpty) {
      await fetchAvailableShops();
    }

    await Future.wait([fetchCategories(), fetchProducts()]);
  }

  void changeCategory(int index) {
    _selectedCategory = index;
    notifyListeners();
  }

  // ========== SELLER IDS MANAGEMENT ==========

  /// Load seller IDs from SharedPreferences
  Future<void> _loadSellerIds() async {
    try {
      _sellerIds = await SharedPrefsHelper.getSellerIds();
      debugPrint('Loaded ${_sellerIds.length} seller IDs: $_sellerIds');
    } catch (e) {
      debugPrint('Error loading seller IDs: $e');
      _sellerIds = [];
    }
  }

  /// Save seller IDs to SharedPreferences
  Future<void> _saveSellerIds(List<int> ids) async {
    try {
      await SharedPrefsHelper.saveSellerIds(ids);
      _sellerIds = ids;
      debugPrint('Saved ${ids.length} seller IDs: $ids');
      notifyListeners();
    } catch (e) {
      debugPrint(' Error saving seller IDs: $e');
    }
  }

  // ========== AVAILABLE SHOPS API ==========

  /// Fetch available shops based on current address
  Future<Map<String, dynamic>?> fetchAvailableShops() async {
    if (_selectedAddress == null) {
      debugPrint('No address selected, cannot fetch available shops');
      return null;
    }

    try {
      debugPrint(
        'Fetching available shops for address: ${_selectedAddress!.fullAddress}',
      );

      final response = await AvailableShopsService.fetchAvailableShops(
        street: _selectedAddress!.road,
        city: _selectedAddress!.city,
        postcode: _selectedAddress!.postCode,
        lat: _selectedAddress!.lat ?? 0.0,
        lon: _selectedAddress!.lon ?? 0.0,
      );

      _availableShopsData = response;

      // Extract and save seller_ids (or empty list if not available)
      if (response['seller_ids'] != null && response['seller_ids'] is List) {
        final List<dynamic> sellerIdsDynamic = response['seller_ids'];
        final List<int> newSellerIds = sellerIdsDynamic
            .map((id) => id as int)
            .toList();

        if (newSellerIds.isNotEmpty) {
          await _saveSellerIds(newSellerIds);
          debugPrint('Available shops fetched successfully');
          debugPrint('Seller IDs: $newSellerIds');
        } else {
          debugPrint(
            'Available shops returned no seller IDs; keeping existing filters',
          );
        }
      } else {
        final message = (response['message'] ?? '').toString().toLowerCase();
        final isBotBlocked =
            message.contains('imunify360') ||
            message.contains('bot-protection') ||
            message.contains('access denied');

        if (isBotBlocked) {
          debugPrint(
            'Available shops request was blocked; preserving existing seller IDs',
          );
          return response;
        }

        await _saveSellerIds([]);
        debugPrint('No seller_ids found in response, saved empty list');
        _availableShopsData = null;
      }

      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Error fetching available shops: $e');
      _availableShopsData = null;
      // Preserve existing seller IDs so normal API calls can continue without a forced empty filter
      debugPrint('Preserving seller IDs after available shops error');
      notifyListeners();
      return null;
    }
  }

  /// Check if there are available products
  bool hasAvailableProducts() {
    return _availableShopsData != null &&
        _availableShopsData!['sellers'] != null &&
        (_availableShopsData!['sellers'] as List).isNotEmpty;
  }

  // ========== ADDRESS MANAGEMENT ==========

  /// Load selected address from SharedPreferences
  Future<void> _loadSelectedAddress() async {
    try {
      final savedAddressJson = await SharedPrefsHelper.getSelectedAddress();

      if (savedAddressJson != null) {
        _selectedAddress = AddressModel.fromJson(savedAddressJson);
        _displayAddress = _selectedAddress!.fullAddress;

        debugPrint('HomeViewModel: Loaded saved address');
        debugPrint('   Full Address: $_displayAddress');
        debugPrint('   City: ${_selectedAddress!.city}');
        debugPrint(
          '   Lat/Lon: ${_selectedAddress!.lat}, ${_selectedAddress!.lon}',
        );
      } else {
        _selectedAddress = null;
        _displayAddress = "Select address";
        debugPrint('HomeViewModel: No saved address found');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('HomeViewModel: Error loading selected address: $e');
      _selectedAddress = null;
      _displayAddress = "Select address";
      notifyListeners();
    }
  }

  ///Update selected address and fetch available shops
  Future<void> updateSelectedAddress(AddressModel address) async {
    try {
      _selectedAddress = address;
      _displayAddress = address.fullAddress;

      // ✅ Save to SharedPreferences with BOTH key formats for compatibility
      final addressJson = {
        'address': address.fullAddress,
        'fullAddress': address.fullAddress,
        'city': address.city,
        'postcode': address.postCode,
        'postCode': address.postCode,
        'road': address.road,
        'house': address.house,
        'room': address.room,
        'lat': address.lat,
        'lon': address.lon,
      };

      await SharedPrefsHelper.saveSelectedAddress(addressJson);

      debugPrint('✅ HomeViewModel: Selected address updated and saved');
      debugPrint('   Display Address: $_displayAddress');
      debugPrint('   City: ${address.city}, Postcode: ${address.postCode}');

      // ✅ Notify listeners BEFORE fetching shops so UI updates immediately
      notifyListeners();

      // Clear old seller IDs before fetching new ones
      await _saveSellerIds([]);
      debugPrint('🔄 Cleared old seller IDs due to address change');

      // Fetch available shops for new address
      await fetchAvailableShops();
    } catch (e) {
      debugPrint('❌ HomeViewModel: Error updating selected address: $e');
    }
  }

  /// Reload address from SharedPreferences (এটা refresh এ call হবে)
  Future<void> reloadAddress() async {
    debugPrint('HomeViewModel: Reloading address from SharedPrefs...');
    await _loadSelectedAddress();
  }

  ///  Get display address for UI - Now synchronous with fallback
  String getDisplayAddress() {
    // যদি _displayAddress empty না হয় তাহলে সেটা return করো
    if (_displayAddress.isNotEmpty && _displayAddress != "Select address") {
      return _displayAddress;
    }

    // যদি _selectedAddress থাকে তাহলে সেটা থেকে নাও
    if (_selectedAddress != null && _selectedAddress!.fullAddress.isNotEmpty) {
      _displayAddress = _selectedAddress!.fullAddress;
      return _displayAddress;
    }

    // Default fallback
    return "Select address";
  }

  /// Clear selected address and seller IDs
  Future<void> clearSelectedAddress() async {
    try {
      await SharedPrefsHelper.clearSelectedAddress();
      await SharedPrefsHelper.clearSellerIds();

      _selectedAddress = null;
      _displayAddress = "Select address";
      _sellerIds = [];
      _availableShopsData = null;

      notifyListeners();
      debugPrint('Selected address and seller IDs cleared');
    } catch (e) {
      debugPrint('Error clearing selected address: $e');
    }
  }

  // ========== CATEGORY & PRODUCT MANAGEMENT ==========

  /// Fetch all subcategories
  Future<void> fetchCategories() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchCategories();
      _subcategories = response.subcategories;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = AppErrorHelper.toUserMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch products from the home/categories endpoint
  Future<void> fetchProducts() async {
    try {
      debugPrint('Fetching products...');
      debugPrint('Current seller IDs: $_sellerIds');

      // যদি seller IDs থাকে তাহলে filter করো, নাহলে সব products আনো
      final Map<String, dynamic> homeData = await _apiService
          .fetchHomeCategories(
            sellerIds: _sellerIds.isNotEmpty ? _sellerIds : null,
          );

      if (_sellerIds.isNotEmpty) {
        debugPrint('Products filtered with ${_sellerIds.length} seller IDs');
      } else {
        debugPrint('Products fetched WITHOUT filtering (showing all sellers)');
      }

      _parseProductsFromHomeResponse(homeData);
      _parseHomeCategories(homeData);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  /// Refresh data - এখানে address reload করতে হবে
  Future<void> refreshData() async {
    debugPrint('HomeViewModel: Refreshing all data...');

    // First reload address from SharedPrefs
    await _loadSelectedAddress();

    // Then load seller IDs
    await _loadSellerIds();

    // If address exists, fetch available shops
    if (_selectedAddress != null) {
      await fetchAvailableShops();
    }

    await fetchCategories();
    await fetchProducts();

    debugPrint('HomeViewModel: Data refresh completed');
  }

  Future<void> refreshCategories() async {
    await fetchCategories();
    await fetchProducts();
  }

  void _parseProductsFromHomeResponse(Map<String, dynamic> response) {
    _productsBySubcategory.clear();

    try {
      if (response['subcategories'] != null) {
        final subcategoriesData =
            response['subcategories'] as Map<String, dynamic>;

        for (var subcatKey in subcategoriesData.keys) {
          final subcatData = subcategoriesData[subcatKey];
          if (subcatData is! Map<String, dynamic>) continue;

          for (var shopKey in subcatData.keys) {
            final shopProducts = subcatData[shopKey];

            if (shopProducts is List) {
              for (var productJson in shopProducts) {
                try {
                  if (productJson is Map<String, dynamic>) {
                    if (!productJson.containsKey('shop_name')) {
                      productJson['shop_name'] = shopKey;
                    }

                    final subcategoryId = _parseInt(
                      productJson['subcategory_id'],
                    );
                    if (!_productsBySubcategory.containsKey(subcategoryId)) {
                      _productsBySubcategory[subcategoryId] = [];
                    }

                    final product = Product.fromJson(productJson);
                    _productsBySubcategory[subcategoryId]!.add(product);
                  }
                } catch (e) {
                  debugPrint('Error parsing product: $e');
                  debugPrint('Product JSON: $productJson');
                }
              }
            }
          }
        }

        debugPrint(
          'Parsed products for ${_productsBySubcategory.length} subcategories',
        );
      }
    } catch (e) {
      debugPrint('Error parsing products from response: $e');
    }
  }

  /// Parse response and organize by subcategory -> seller -> products
  void _parseHomeCategories(Map<String, dynamic> response) {
    _subcategoriesWithProducts.clear();

    try {
      if (response['subcategories'] != null) {
        final subcategoriesData =
            response['subcategories'] as Map<String, dynamic>;

        for (var subcategoryName in subcategoriesData.keys) {
          final subcategoryData = subcategoriesData[subcategoryName];

          if (subcategoryData is! Map<String, dynamic>) continue;

          List<Map<String, dynamic>> sellers = [];

          for (var sellerName in subcategoryData.keys) {
            final productsData = subcategoryData[sellerName];

            if (productsData is List) {
              List<Map<String, dynamic>> products = [];

              for (var productJson in productsData) {
                if (productJson is Map<String, dynamic>) {
                  try {
                    products.add(_parseProduct(productJson));
                  } catch (e) {
                    debugPrint('Error parsing product in category: $e');
                    debugPrint('Product JSON: $productJson');
                  }
                }
              }

              if (products.isNotEmpty) {
                sellers.add({'name': sellerName, 'products': products});
              }
            }
          }

          if (sellers.isNotEmpty) {
            _subcategoriesWithProducts.add({
              'name': subcategoryName,
              'sellers': sellers,
            });
          }
        }

        debugPrint(
          'Parsed ${_subcategoriesWithProducts.length} subcategories with products',
        );
        debugPrint(
          'Total sellers found: ${_subcategoriesWithProducts.fold(0, (sum, subcat) => sum + (subcat['sellers'] as List).length)}',
        );
      }
    } catch (e) {
      debugPrint('Error parsing home categories: $e');
    }
  }

  /// Parse a single product with proper type handling
  Map<String, dynamic> _parseProduct(Map<String, dynamic> json) {
    final int productId = _parseInt(json['shop_product_id']);

    return {
      'id': productId,
      'name': json['name'] ?? '',
      'image': json['image'] ?? '',
      'price': _parsePrice(json['sales_price_with_charge']),
      'originalPrice': _parsePrice(json['sale_price']),
      'weight': json['weight']?.toString() ?? '',
      'unit': json['unit_name'] ?? '',
      'hasOffer': _parseBool(json['has_offer']),
      'isInWishlist': _wishlistManager.isInWishlist(productId),
      'sellerId': _parseInt(json['seller_id']),
      'sellerName': json['shop_name'] ?? '',
      'subcategoryId': _parseInt(json['subcategory_id']),
      'quantity': 0,
    };
  }

  /// Safely parse int from dynamic value
  int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is double) return value.toInt();
    return 0;
  }

  /// Safely parse double/price from dynamic value
  double _parsePrice(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Safely parse bool from dynamic value
  bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1' || lower == 'yes';
    }
    return false;
  }

  /// Get products for a specific subcategory
  List<Product> getProductsForSubcategory(int subcategoryId) {
    return _productsBySubcategory[subcategoryId] ?? [];
  }

  /// Get all subcategories that have products
  List<Subcategory> getSubcategoriesWithProducts() {
    return _subcategories.where((subcategory) {
      return _productsBySubcategory.containsKey(subcategory.id) &&
          _productsBySubcategory[subcategory.id]!.isNotEmpty;
    }).toList();
  }

  /// Update product quantity (for old Product model)
  void updateProductQuantity(
    int productId,
    int subcategoryId,
    int newQuantity,
  ) {
    final products = _productsBySubcategory[subcategoryId];
    if (products == null) return;

    final index = products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      _productsBySubcategory[subcategoryId]![index] = products[index].copyWith(
        quantity: newQuantity,
      );
      notifyListeners();
    }
  }

  /// Update product quantity (for new structure)
  void updateProductQuantityNew(
    int productId,
    String subcategoryName,
    String sellerName,
    int newQuantity,
  ) {
    for (var subcategory in _subcategoriesWithProducts) {
      if (subcategory['name'] == subcategoryName) {
        List<Map<String, dynamic>> sellers = subcategory['sellers'];

        for (var seller in sellers) {
          if (seller['name'] == sellerName) {
            List<Map<String, dynamic>> products = seller['products'];

            for (var i = 0; i < products.length; i++) {
              if (products[i]['id'] == productId) {
                products[i]['quantity'] = newQuantity;
                notifyListeners();
                return;
              }
            }
          }
        }
      }
    }
  }

  /// Toggle wishlist - Now uses WishlistManager (for old Product model)
  Future<void> toggleWishlist(
    BuildContext context,
    int productId,
    int subcategoryId,
  ) async {
    await _wishlistManager.toggleWishlist(context, productId);

    // Update local product state
    final products = _productsBySubcategory[subcategoryId];
    if (products != null) {
      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final isInWishlist = _wishlistManager.isInWishlist(productId);
        _productsBySubcategory[subcategoryId]![index] = products[index]
            .copyWith(isInWishlist: isInWishlist);
      }
    }

    notifyListeners();
  }

  /// Toggle wishlist (for new structure) - Now uses WishlistManager
  Future<void> toggleWishlistNew(
    BuildContext context,
    int productId,
    String subcategoryName,
    String sellerName,
  ) async {
    await _wishlistManager.toggleWishlist(context, productId);

    // Update local product state
    for (var subcategory in _subcategoriesWithProducts) {
      if (subcategory['name'] == subcategoryName) {
        List<Map<String, dynamic>> sellers = subcategory['sellers'];

        for (var seller in sellers) {
          if (seller['name'] == sellerName) {
            List<Map<String, dynamic>> products = seller['products'];

            for (var i = 0; i < products.length; i++) {
              if (products[i]['id'] == productId) {
                products[i]['isInWishlist'] = _wishlistManager.isInWishlist(
                  productId,
                );
                notifyListeners();
                return;
              }
            }
          }
        }
      }
    }

    notifyListeners();
  }
}
