// lib/presentation/category/categories_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../home/home_viewmodel.dart';
import '../widgets/category_tabs_widget.dart';
import '../widgets/category_card_widget.dart';

class CategoriesView extends StatelessWidget {
  const CategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HomeViewModel>();

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
        shadowColor: Colors.grey.withValues(alpha: 0.1),
        // leading: IconButton(
        //   icon: const Icon(Icons.arrow_back, color: Colors.black),
        //   onPressed: () {
        //     Navigator.pop(context);
        //   },
        // ),
        title: const Text(
          'All Categories',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        // centerTitle: false,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.search, color: Colors.black87),
        //     onPressed: () {
        //       // TODO: Implement search
        //     },
        //   ),
        // ],
      ),
      body: Column(
        children: [
          CategoryTabsWidget(
            selectedCategory: vm.selectedCategory,
            onCategoryChanged: (index) => vm.changeCategory(index),
            categoryNames: const ["Grocery", "Fashion", "Air Tickets"],
          ),
          Expanded(
            child: vm.isLoading
                ? _buildLoadingState()
                : vm.errorMessage != null
                ? _buildErrorState(vm)
                : vm.subcategories.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: () => vm.refreshCategories(),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.7,
                          ),
                      itemCount: vm.subcategories.length,
                      itemBuilder: (context, index) {
                        final subcategory = vm.subcategories[index];
                        return CategoryCardWidget(subcategory: subcategory);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(HomeViewModel vm) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Categories',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              vm.errorMessage ?? 'Something went wrong',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => vm.refreshCategories(),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text(
                'Try Again',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B35),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
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
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.category_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Categories Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Categories will appear here once they are available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.7,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: const Color(0xFFF1ECE5),
        highlightColor: const Color(0xFFFBF8F4),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
