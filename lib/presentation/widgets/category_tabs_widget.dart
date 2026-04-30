// lib/presentation/widgets/category_tabs_widget.dart

import 'package:flutter/material.dart';

class CategoryTabsWidget extends StatelessWidget {
  final int selectedCategory;
  final Function(int) onCategoryChanged;
  final List<String> categoryNames;

  final List<String>? categoryImages;
  final List<IconData>? categoryIcons;
  final List<List<Color>>? categoryGradients;

  const CategoryTabsWidget({
    super.key,
    required this.selectedCategory,
    required this.onCategoryChanged,
    required this.categoryNames,
    this.categoryImages,
    this.categoryIcons,
    this.categoryGradients,
  });

  // Default images if not provided
  List<String> get _defaultImages =>
      categoryImages ??
      [
        'assets/images/ic_grocery.png',
        'assets/images/ic_fashion.png',
        'assets/images/ic_tickets.png',
      ];

  // Default icons if images fail to load
  List<IconData> get _icons =>
      categoryIcons ??
      [
        Icons.shopping_cart_rounded,
        Icons.checkroom_rounded,
        Icons.flight_takeoff_rounded,
      ];

  // Default gradients if not provided
  List<List<Color>> get _gradients =>
      categoryGradients ??
      [
        [const Color(0xFFFF9933), const Color(0xFFFFAA55)],
        [const Color(0xFFE91E63), const Color(0xFFF06292)],
        [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)],
      ];

  // Background colors for non-selected tabs
  List<Color> get _bgColors => [
    const Color(0xFFF5F5F5),
    const Color(0xFFF5F5F5),
    const Color(0xFFF5F5F5),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(categoryNames.length, (index) {
            final selected = selectedCategory == index;
            return Padding(
              padding: EdgeInsets.only(
                right: index < categoryNames.length - 1 ? 8 : 0,
              ),
              child: GestureDetector(
                onTap: () => onCategoryChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? LinearGradient(
                            colors: _gradients[index % _gradients.length],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                        : null,
                    color: selected
                        ? null
                        : _bgColors[index % _bgColors.length],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: _gradients[index % _gradients.length][0]
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 0,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildImageOrIcon(index, selected),
                      const SizedBox(width: 8),
                      Text(
                        categoryNames[index],
                        style: TextStyle(
                          color: selected ? Colors.black87 : Colors.black54,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 14,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildImageOrIcon(int index, bool selected) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: selected ? Colors.white.withValues(alpha: 0.9) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipOval(child: _buildContent(index, selected)),
    );
  }

  Widget _buildContent(int index, bool selected) {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Image.asset(
        _defaultImages[index % _defaultImages.length],
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            _icons[index % _icons.length],
            color: _gradients[index % _gradients.length][0],
            size: 18,
          );
        },
      ),
    );
  }
}
