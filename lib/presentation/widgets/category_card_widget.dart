// lib/presentation/widgets/category_card_widget.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../core/utils/category_image_cache_manager.dart';
import '../products/product_list_view.dart';
import '../products/product_list_viewmodel.dart';

class CategoryCardWidget extends StatelessWidget {
  final dynamic subcategory;

  const CategoryCardWidget({super.key, required this.subcategory});

  @override
  Widget build(BuildContext context) {
    final imageUrl = CategoryImageCacheManager.resolveUrl(subcategory.appImage);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider(
              create: (_) => ProductListViewModel(),
              child: ProductListView(
                subcategoryId: subcategory.id,
                categoryName: subcategory.name,
              ),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              spreadRadius: 0,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // Full Background Image
              Positioned.fill(
                child: imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        fadeInDuration: Duration.zero,
                        placeholderFadeInDuration: Duration.zero,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFF6B35),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) =>
                            _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),

              // Text Overlay at Top Left
              Positioned(
                top: 20,
                left: 10,
                right: 70,
                child: Text(
                  subcategory.name ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.3,
                    shadows: [
                      // Shadow(
                      //   color: Colors.white,
                      //   offset: Offset(0, 0),
                      //   blurRadius: 10,
                      // ),
                      // Shadow(
                      //   color: Colors.white,
                      //   offset: Offset(1, 1),
                      //   blurRadius: 6,
                      // ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 40, color: Colors.grey[400]),
          const SizedBox(height: 6),
          Text(
            'No Image',
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}
