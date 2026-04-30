// lib/presentation/favorites/favorites_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_error_helper.dart';
import '../../core/utils/wishlist_manager.dart';
import '../../data/models/wishlist_model.dart';
import '../widgets/product_card_widget.dart';
import 'dart:developer' as developer;

class FavoritesView extends StatefulWidget {
  const FavoritesView({super.key});

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> {
  static const _pageBg = Color(0xFFF8F4ED);
  static const _surface = Colors.white;
  static const _ink = Color(0xFF2C211B);
  static const _muted = Color(0xFF7C6A5F);
  static const _line = Color(0xFFE8DDD1);
  static const _primary = Color(0xFFE86C39);
  static const _accent = Color(0xFFE91E63);
  static const _headerGradient = [Color(0xFFF39A6C), Color(0xFFE86C39)];

  @override
  void initState() {
    super.initState();
    // Safely schedule loading after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadWishlist();
      }
    });
  }

  Future<void> _loadWishlist() async {
    if (!mounted) return;

    try {
      final wishlistManager = context.read<WishlistManager>();
      await wishlistManager.loadWishlist();
    } catch (e) {
      developer.log('Error loading wishlist: $e');
      if (mounted) {
        AppErrorHelper.showSnackBar(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Favorites',
          style: TextStyle(
            color: _ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Consumer<WishlistManager>(
        builder: (context, wishlistManager, child) {
          final screenWidth = MediaQuery.of(context).size.width;
          final horizontalPadding = screenWidth < 360 ? 12.0 : 16.0;
          final gridSpacing = screenWidth < 360 ? 12.0 : 14.0;
          final crossAxisCount = screenWidth >= 900
              ? 4
              : screenWidth >= 640
              ? 3
              : 2;
          final totalSpacing =
              (horizontalPadding * 2) + (gridSpacing * (crossAxisCount - 1));
          final cardWidth = (screenWidth - totalSpacing) / crossAxisCount;
          final cardHeight = (cardWidth * (screenWidth < 360 ? 1.74 : 1.68))
              .clamp(250.0, 320.0);

          if (wishlistManager.isLoading) {
            return Stack(
              children: [
                _buildBackgroundDecor(),
                const Center(child: CircularProgressIndicator(color: _primary)),
              ],
            );
          }

          return Stack(
            children: [
              _buildBackgroundDecor(),
              RefreshIndicator(
                onRefresh: _loadWishlist,
                color: _primary,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _buildHeroHeader(
                        wishlistManager.wishlistItems.length,
                      ),
                    ),
                    if (wishlistManager.wishlistItems.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _buildEmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          8,
                          horizontalPadding,
                          24,
                        ),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final wishlistItem =
                                wishlistManager.wishlistItems[index];
                            return _buildProductCard(context, wishlistItem);
                          }, childCount: wishlistManager.wishlistItems.length),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                mainAxisExtent: cardHeight,
                                crossAxisSpacing: gridSpacing,
                                mainAxisSpacing: gridSpacing,
                              ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _primary.withValues(alpha: 0.20),
                  _primary.withValues(alpha: 0.03),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          top: 140,
          left: -70,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  _accent.withValues(alpha: 0.16),
                  _accent.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeroHeader(int itemCount) {
    final subtitle = itemCount == 0
        ? 'Save the products you love and come back to them anytime.'
        : 'Your handpicked products are ready for a quick reorder.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _headerGradient,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primary.withValues(alpha: 0.24),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Text(
                        '$itemCount saved',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Text(
                  'Your Favorite Picks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildInfoChip(
                      icon: Icons.auto_awesome_rounded,
                      label: itemCount == 0
                          ? 'Start curating'
                          : 'Freshly saved',
                    ),
                    _buildInfoChip(
                      icon: Icons.shopping_bag_outlined,
                      label: 'Ready for reorder',
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (itemCount > 0) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  const Text(
                    'Saved products',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Pull down to refresh',
                    style: TextStyle(
                      color: _muted.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accent.withValues(alpha: 0.18),
                      _accent.withValues(alpha: 0.06),
                    ],
                  ),
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 40,
                  color: _accent,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Nothing saved yet',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  color: _ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tap the heart on any product and it will appear here for quick access later.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: _muted,
                  height: 1.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1EB),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Curate your next grocery list',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, WishlistItem wishlistItem) {
    final shopProduct = wishlistItem.shopProduct;
    final product = shopProduct.product;

    final weight = shopProduct.weight?.isNotEmpty == true
        ? shopProduct.weight!
        : (product?.weightQuantity ?? '1');

    final imageUrl = _constructImageUrl(shopProduct.productImage);
    final actualProductId = int.tryParse(shopProduct.productId) ?? 0;

    final productData = {
      'id': shopProduct.id,
      'productId': actualProductId,
      'name': shopProduct.productName,
      'image': shopProduct.productImage,
      'imageUrl': imageUrl,
      'price': double.tryParse(shopProduct.salePrice) ?? 0.0,
      'originalPrice': double.tryParse(shopProduct.salesPriceWithCharge) ?? 0.0,
      'weight': weight,
      'unit': product?.weightUnit ?? 'kg',
      'displayWeight': '$weight ${product?.weightUnit ?? "kg"}',
      'hasOffer':
          shopProduct.discountAmount != null &&
          shopProduct.discountAmount!.isNotEmpty &&
          shopProduct.discountAmount != '0' &&
          shopProduct.discountAmount != '0.00',
      'sellerId': int.tryParse(shopProduct.sellerId) ?? 0,
    };

    return ProductCardWidget(
      product: productData,
      sellerName: 'Seller ${shopProduct.sellerId}',
      onWishlistToggle: () async {
        if (!mounted) return;

        developer.log('Removing from wishlist: ${wishlistItem.id}');
        final wishlistManager = context.read<WishlistManager>();
        final success = await wishlistManager.removeFromWishlist(
          context,
          wishlistItem.id,
        );
        if (success && mounted) {
          developer.log('Successfully removed from wishlist');
        }
      },
      onQuantityChanged: (newQuantity) {
        developer.log('Quantity changed: $newQuantity');
      },
      onTap: () {
        developer.log('Product tapped: ${shopProduct.productName}');
      },
      useHorizontalLayout: false,
      forceWishlistSelected: true,
      wishlistIconBackgroundColor: const Color(0xFFFFEEF3),
      wishlistSelectedColor: const Color(0xFFE91E63),
    );
  }

  String _constructImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';

    if (imagePath.startsWith('http')) {
      return imagePath.replaceAll('\\', '/');
    }

    final cleanPath = imagePath.replaceAll('\\', '/');
    final encodedPath = cleanPath.replaceAll(' ', '%20');
    return 'https://bideshibazar.com/uploads/product/$encodedPath';
  }
}
