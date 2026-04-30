// lib/presentation/products/product_list_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'product_list_viewmodel.dart';
import '../widgets/product_card_widget.dart';
import 'product_detail_view.dart';
import '../../core/network/api_constants.dart';

class ProductListView extends StatefulWidget {
  final int? subcategoryId;
  final int? storeId;
  final String categoryName;

  const ProductListView({
    super.key,
    this.subcategoryId,
    this.storeId,
    required this.categoryName,
  });

  @override
  State<ProductListView> createState() => _ProductListViewState();
}

class _ProductListViewState extends State<ProductListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ProductListViewModel>();

      if (widget.subcategoryId != null) {
        vm.fetchProducts(widget.subcategoryId!);
      } else if (widget.storeId != null) {
        vm.fetchProductsByStore(widget.storeId!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductListViewModel>();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.grey.withOpacity(0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: vm.isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      )
          : vm.errorMessage != null
          ? _buildErrorState(vm)
          : Column(
        children: [
          if (vm.shopNames.isNotEmpty) _buildShopFilter(vm),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                if (widget.subcategoryId != null) {
                  return vm.refreshProducts(widget.subcategoryId!);
                } else if (widget.storeId != null) {
                  return vm.refreshProductsByStore(widget.storeId!);
                }
                return Future.value();
              },
              child: vm.filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : _buildProductGrid(vm),
            ),
          ),
        ],
      ),
    );
  }

  // Shop Filter Chips
  Widget _buildShopFilter(ProductListViewModel vm) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: vm.shopNames.length,
        itemBuilder: (context, index) {
          final shopName = vm.shopNames[index];
          final isSelected = vm.selectedShop == shopName;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(shopName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  vm.selectShop(shopName);
                }
              },
              backgroundColor: Colors.grey[100],
              selectedColor: const Color(0xFFFFA726),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFFFFA726)
                      : Colors.grey.shade300,
                  width: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Product Grid
  Widget _buildProductGrid(ProductListViewModel vm) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.68,
      ),
      itemCount: vm.filteredProducts.length,
      itemBuilder: (context, index) {
        final product = vm.filteredProducts[index];
        return _buildProductCard(product, vm);
      },
    );
  }

  // Product Card - Using unified ProductCardWidget
  Widget _buildProductCard(product, ProductListViewModel vm) {
    final int productId = product.id is String
        ? int.tryParse(product.id) ?? 0
        : (product.id ?? 0);

    final productData = vm.getProductData(productId);
    final int quantity = productData['quantity'] ?? 0;
    final bool isInWishlist = productData['isInWishlist'] ?? false;

    // Fix image URL
    final String rawImage = (product.imageUrl ?? '').trim();
    String imageUrl;

    print(' Image URL Processing');
    print(' Product Name: ${product.name}');
    print('Raw Image: "$rawImage"');
    print(' Base URL: ${ApiConstants.imageBaseUrl}');

    if (rawImage.isEmpty) {
      imageUrl = '';
      print(' Image is empty');
    } else if (rawImage.startsWith('http')) {
      final uri = Uri.parse(rawImage);
      final pathSegments = uri.pathSegments;

      final productIndex = pathSegments.indexOf('product');
      if (productIndex != -1 && productIndex < pathSegments.length - 1) {
        final remainingPath = pathSegments.sublist(productIndex + 1).join('/');
        imageUrl = '${ApiConstants.imageBaseUrl}uploads/product/$remainingPath';
        print(' Extracted path after "product/": "$remainingPath"');
      } else {
        final filename = pathSegments.last;
        imageUrl = '${ApiConstants.imageBaseUrl}uploads/product/$filename';
        print(' Using filename only: "$filename"');
      }
      print(' Final URL: $imageUrl');
    } else {
      imageUrl = '${ApiConstants.imageBaseUrl}uploads/product/$rawImage';
      print(' Using raw path as is: "$rawImage"');
      print(' Final URL: $imageUrl');
    }

    // Create wrapper that includes state and fixed image URL
    final productWithState = _ProductWrapper(
      product: product,
      quantity: quantity,
      isInWishlist: isInWishlist,
      fixedImageUrl: imageUrl,
    );

    return ProductCardWidget(
      product: productWithState,
      sellerName: product.shopName ?? '',
      useHorizontalLayout: false,
      onWishlistToggle: () {
        // Toggle wishlist with context
        vm.toggleWishlist(context, productId);
      },
      onQuantityChanged: (newQuantity) {
        vm.updateProductQuantity(productId, newQuantity);
      },
      onTap: () {
        print('Product tapped: ${product.name}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailView(
              shopProductId: productId,
              productName: product.name ?? product.title ?? 'Product Details',
            ),
          ),
        );
      },
    );
  }

  // Error State
  Widget _buildErrorState(ProductListViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              'Error loading products',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              vm.errorMessage ?? 'Unknown error',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                if (widget.subcategoryId != null) {
                  vm.refreshProducts(widget.subcategoryId!);
                } else if (widget.storeId != null) {
                  vm.refreshProductsByStore(widget.storeId!);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Empty State
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No products available',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back later for new products',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// Wrapper class to pass product with state
class _ProductWrapper {
  final dynamic product;
  final int quantity;
  final bool isInWishlist;
  final String fixedImageUrl;

  _ProductWrapper({
    required this.product,
    required this.quantity,
    required this.isInWishlist,
    required this.fixedImageUrl,
  });

  dynamic get id => _safe(() => product.id, '0');
  String get name => _safe(() => product.name ?? product.title, '');
  String get title => _safe(() => product.title, '');
  String get imageUrl => fixedImageUrl;
  String get price => _safe(() => product.price, '0.0');
  String get oldPrice => _safe(() => product.oldPrice, '0.0');
  String get weight => _safe(() => product.weight, '');
  String get unit => _safe(() => product.unit, '');
  String get displayWeight => _safe(() => product.displayWeight, '');
  bool get hasOffer => _safe(() => product.hasOffer, false);
  String get shopName => _safe(() => product.shopName ?? product.vendorName, '');

  T _safe<T>(T Function() getter, T defaultValue) {
    try {
      final result = getter();
      return result ?? defaultValue;
    } catch (e) {
      return defaultValue;
    }
  }
}