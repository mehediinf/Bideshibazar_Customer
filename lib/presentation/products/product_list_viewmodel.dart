// lib/presentation/products/product_list_viewmodel.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../data/models/product_list_model.dart';
import '../../core/network/api_constants.dart';
import '../../core/utils/app_error_helper.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/utils/wishlist_manager.dart';

class ProductListViewModel extends ChangeNotifier {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );

  final WishlistManager _wishlistManager = WishlistManager();

  ProductListResponse? _productListResponse;
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedShop = '';

  // Store products (separate from subcategory products)
  List<Product> _storeProducts = [];
  bool _isStoreMode = false;

  // Track product quantities (cart quantities only)
  final Map<int, int> _productQuantities = {};

  ProductListResponse? get productListResponse => _productListResponse;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get selectedShop => _selectedShop;

  // Get all shop names
  List<String> get shopNames {
    if (_isStoreMode) {
      return [];
    }

    if (_productListResponse == null) return [];
    return _productListResponse!.data.keys.toList();
  }

  // Get filtered products based on selected shop
  List<Product> get filteredProducts {
    if (_isStoreMode) {
      return _storeProducts;
    }

    if (_productListResponse == null) return [];

    if (_selectedShop.isEmpty && _productListResponse!.data.isNotEmpty) {
      return _productListResponse!.data.values.first;
    }

    return _productListResponse!.data[_selectedShop] ?? [];
  }

  // Get product data (quantity and wishlist status)
  Map<String, dynamic> getProductData(int productId) {
    return {
      'quantity': _productQuantities[productId] ?? 0,
      'isInWishlist': _wishlistManager.isInWishlist(productId),
    };
  }

  // Update product quantity
  void updateProductQuantity(int productId, int newQuantity) {
    _productQuantities[productId] = newQuantity;
    notifyListeners();
  }

  // Toggle wishlist
  Future<void> toggleWishlist(BuildContext context, int productId) async {
    await _wishlistManager.toggleWishlist(context, productId);
    notifyListeners(); // Update UI after wishlist change
  }

  // Change selected shop
  void selectShop(String shopName) {
    _selectedShop = shopName;
    notifyListeners();
  }

  // Fetch products by subcategory ID with seller filtering
  Future<void> fetchProducts(int subcategoryId) async {
    _isStoreMode = false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Fetching products for subcategory: $subcategoryId');

      // Get saved seller IDs from SharedPreferences
      final List<int> savedSellerIds = await SharedPrefsHelper.getSellerIds();

      // Build URL with seller_ids parameter if available
      String url = '${ApiConstants.baseUrl}category/$subcategoryId';

      if (savedSellerIds.isNotEmpty) {
        final sellerIdsParam = savedSellerIds.join(',');
        url += '?seller_ids=$sellerIdsParam';
        debugPrint('Using saved seller IDs: $sellerIdsParam');
      } else {
        debugPrint('No saved seller IDs - fetching all products');
      }

      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) {
            return status != null && status < 600;
          },
        ),
      );

      debugPrint('Response Status: ${response.statusCode}');

      if (response.statusCode != null &&
          (response.statusCode! >= 520 && response.statusCode! <= 530)) {
        _errorMessage =
        'Server temporarily unavailable (Error ${response.statusCode}). Please try again later.';
        debugPrint('Cloudflare Error: ${response.statusCode}');
      } else if (response.statusCode == 200) {
        if (response.data != null && response.data is Map) {
          _productListResponse = ProductListResponse.fromJson(response.data);
          final shops = _productListResponse!.data.keys.toList();
          _selectedShop = shops.isNotEmpty ? shops.first : '';
          debugPrint(
            'Products loaded successfully: ${filteredProducts.length} items',
          );
        } else {
          _errorMessage = 'Invalid response format from server';
          debugPrint('Invalid response format');
        }
      } else {
        _errorMessage = 'Failed to load products (Error ${response.statusCode})';
        debugPrint('HTTP Error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('DioException occurred: ${e.type}');
      _errorMessage = AppErrorHelper.toUserMessage(e);

      debugPrint('Error details: ${e.message}');
    } catch (e) {
      _errorMessage = AppErrorHelper.toUserMessage(e);
      debugPrint('Unexpected error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch products by store ID
  Future<void> fetchProductsByStore(int storeId) async {
    _isStoreMode = true;
    _isLoading = true;
    _errorMessage = null;
    _storeProducts = [];
    notifyListeners();

    try {
      debugPrint('Fetching products for store: $storeId');

      final response = await _dio.get(
        '${ApiConstants.baseUrl}store/$storeId',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          validateStatus: (status) {
            return status != null && status < 600;
          },
        ),
      );

      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Type: ${response.data.runtimeType}');

      if (response.statusCode != null &&
          (response.statusCode! >= 520 && response.statusCode! <= 530)) {
        _errorMessage =
        'Server temporarily unavailable (Error ${response.statusCode}). Please try again later.';
        debugPrint('Cloudflare Error: ${response.statusCode}');
      } else if (response.statusCode == 200) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;

          debugPrint('Response Keys: ${data.keys.toList()}');

          if (data.containsKey('products') && data['products'] is List) {
            final productsJson = data['products'] as List;
            debugPrint('Products count in response: ${productsJson.length}');

            _storeProducts = [];
            for (var i = 0; i < productsJson.length; i++) {
              try {
                final productJson = productsJson[i];

                if (productJson is Map<String, dynamic>) {
                  final productWithSellerId = Map<String, dynamic>.from(productJson);
                  productWithSellerId['seller_id'] = storeId;

                  final product = Product.fromJson(productWithSellerId);
                  _storeProducts.add(product);
                } else {
                  debugPrint(
                    'Product at index $i is not a Map: ${productJson.runtimeType}',
                  );
                }
              } catch (e, stackTrace) {
                debugPrint('Error parsing product at index $i: $e');
                debugPrint('Product JSON: ${productsJson[i]}');
                debugPrint('Stack trace: $stackTrace');
              }
            }

            debugPrint(
              'Store products loaded successfully: ${_storeProducts.length} items',
            );

            if (_storeProducts.isEmpty && productsJson.isNotEmpty) {
              _errorMessage = 'Failed to parse any products';
            }
          } else {
            _errorMessage = 'No products found for this store';
            debugPrint('Products key missing or invalid in response');
          }
        } else {
          _errorMessage = 'Invalid response format from server';
          debugPrint('Invalid response format - not a Map');
        }
      } else {
        _errorMessage = 'Failed to load store products (Error ${response.statusCode})';
        debugPrint('HTTP Error: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('DioException occurred: ${e.type}');
      _errorMessage = AppErrorHelper.toUserMessage(e);

      debugPrint('Error details: ${e.message}');
    } catch (e, stackTrace) {
      _errorMessage = AppErrorHelper.toUserMessage(e);
      debugPrint('Unexpected error: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh products (subcategory)
  Future<void> refreshProducts(int subcategoryId) async {
    await fetchProducts(subcategoryId);
  }

  // Refresh store products
  Future<void> refreshProductsByStore(int storeId) async {
    await fetchProductsByStore(storeId);
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }
}
