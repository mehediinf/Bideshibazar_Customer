// lib/presentation/search/search_view.dart

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import '../../core/network/api_constants.dart';
import '../../core/utils/app_error_helper.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../widgets/search_product_card_widget.dart';
import '../products/product_detail_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchController.text.isEmpty) {
        setState(() {
          _searchResults = [];
          _searchQuery = '';
          _errorMessage = null;
        });
      }
    });
  }

  Future<void> _performSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;

    final trimmedKeyword = keyword.trim();

    setState(() {
      _isLoading = true;
      _searchQuery = trimmedKeyword;
      _errorMessage = null;
    });

    try {
      final List<int> savedSellerIds = await SharedPrefsHelper.getSellerIds();

      // Build URL with seller_ids parameter
      String url = '${ApiConstants.baseUrl}${ApiConstants.search}?keyword=${Uri.encodeComponent(trimmedKeyword)}';

      if (savedSellerIds.isNotEmpty) {
        final sellerIdsParam = savedSellerIds.join(',');
        url += '&seller_ids=$sellerIdsParam';
      } else {
        developer.log('No saved seller IDs - searching all sellers');
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout');
        },
      );


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> allProducts = [];

        // Extract products from all shops
        if (data['data'] != null) {
          data['data'].forEach((shopName, products) {
            if (products is List) {
              allProducts.addAll(products);
            }
          });
        }

        // Log first product structure for debugging
        if (allProducts.isNotEmpty) {
          developer.log('📋 First product structure:');
          developer.log(json.encode(allProducts[0]));
        }

        setState(() {
          _searchResults = allProducts;
          _isLoading = false;
          _errorMessage = allProducts.isEmpty ? 'No products found for "$trimmedKeyword"' : null;
        });
      } else {
        setState(() {
          _isLoading = false;
          _searchResults = [];
          _errorMessage = 'Failed to load products. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _searchResults = [];
        _errorMessage = AppErrorHelper.toUserMessage(e);
      });
    }
  }

  void _navigateToProductDetail(dynamic product) {
    // Try different possible field names for the product ID
    final dynamic productIdRaw = product['id'] ??
        product['shop_product_id'] ??
        product['product_id'] ??
        product['shopProductId'];

    // Convert to int if it's a String
    int? shopProductId;
    if (productIdRaw is int) {
      shopProductId = productIdRaw;
    } else if (productIdRaw is String) {
      shopProductId = int.tryParse(productIdRaw);
    }

    final String? productName = product['name'];

    if (shopProductId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailView(
            shopProductId: shopProductId!,
            productName: productName,
          ),
        ),
      ).then((_) {
        developer.log('Returned from ProductDetailView');
      });
    } else {
     
      // Show error to user
      if (mounted) {
        AppErrorHelper.showSnackBar(
          context,
          null,
          fallback: 'This product could not be opened right now.',
        );
      }
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _searchQuery = '';
      _errorMessage = null;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Container(
          height: 45,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(25),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: _performSearch,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Search for products',
              hintStyle: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[600],
                size: 22,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onPressed: _clearSearch,
              )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Query Header
          if (_searchQuery.isNotEmpty && !_isLoading)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                        ),
                        children: [
                          const TextSpan(text: 'Results for '),
                          TextSpan(
                            text: '"$_searchQuery"',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                          ),
                          if (_searchResults.isNotEmpty)
                            TextSpan(
                              text: ' (${_searchResults.length})',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Main Content Area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildSearchResults();
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF42A5F5)),
          ),
          const SizedBox(height: 16),
          Text(
            'Searching for products...',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                if (_searchQuery.isNotEmpty) {
                  _performSearch(_searchQuery);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF42A5F5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? 'Search for products'
                : 'No products found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Try different keywords',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final product = _searchResults[index];
        return SearchProductCardWidget(
          product: product,
          onTap: () {
            _navigateToProductDetail(product);
          },
        );
      },
    );
  }
}
