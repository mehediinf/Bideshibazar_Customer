// lib/presentation/store/store_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'store_viewmodel.dart';
import '../products/product_list_view.dart';
import '../products/product_list_viewmodel.dart';
import '../widgets/category_tabs_widget.dart';

class StoreView extends StatelessWidget {
  const StoreView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => StoreViewModel(),
      child: const _StoreViewContent(),
    );
  }
}

class _StoreViewContent extends StatelessWidget {
  const _StoreViewContent();

  final List<Color> bgColors = const [
    Colors.white,
    Color(0xFFFFD9E8),
    Color(0xFFCCECFF),
  ];

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<StoreViewModel>();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: Container(
        color: bgColors[vm.selectedCategory],
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),

    //CategoryTabsWidget
              CategoryTabsWidget(
                selectedCategory: vm.selectedCategory,
                onCategoryChanged: (index) => vm.changeCategory(index),
                categoryNames: vm.categories
              ),
              const SizedBox(height: 10),
              Expanded(
                child: vm.selectedCategory == 0
                    ? _buildStoreList(vm, context)
                    : _buildComingSoon(vm.categories[vm.selectedCategory]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // InkWell(
          //   onTap: () => Navigator.pop(context),
          //   borderRadius: BorderRadius.circular(10),
          //   child: Container(
          //     padding: const EdgeInsets.all(8),
          //     decoration: BoxDecoration(
          //       color: Colors.grey[100],
          //       borderRadius: BorderRadius.circular(10),
          //     ),
          //     child: const Icon(
          //       Icons.arrow_back_ios_rounded,
          //       size: 20,
          //       color: Color(0xFFFF6B35),
          //     ),
          //   ),
          // ),
          const SizedBox(width: 12),
          const Text(
            'Popular Stores',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreList(StoreViewModel vm, BuildContext context) {
    if (vm.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF6B35),
        ),
      );
    }

    if (vm.errorMessage != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 12),
              Text(
                'Error loading stores',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => vm.refreshStores(),
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

    if (vm.stores.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No stores available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => vm.refreshStores(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        itemCount: vm.stores.length,
        itemBuilder: (context, index) {
          final store = vm.stores[index];
          return _buildStoreCard(context, store);
        },
      ),
    );
  }

  Widget _buildStoreCard(BuildContext context, store) {
    final imageUrl = store.fullStoreImageUrl;

    return GestureDetector(
      onTap: () {
        print('Navigating to store products: ${store.id} - ${store.shopName}');

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => ProductListViewModel(),
              child: ProductListView(
                storeId: store.id,
                categoryName: store.shopName,
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFB3D9F2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: imageUrl != null
                    ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.store,
                    size: 50,
                    color: Colors.grey.shade400,
                  ),
                )
                    : Icon(
                  Icons.store,
                  size: 50,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                store.shopName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Since ${store.establishedYear}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF2196F3),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2196F3).withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${store.productsCount} Products',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 20),

            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 30),
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      store.address,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(
                    Icons.phone,
                    size: 20,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    store.phone,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildComingSoon(String title) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_empty, size: 60, color: Colors.orange),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              "Coming Soon!",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}