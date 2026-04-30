class CategoryItem {
  final int id;
  final String name;
  final String imageUrl;

  CategoryItem({
    required this.id,
    required this.name,
    required this.imageUrl,
  });

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    return CategoryItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      imageUrl: json['app_image'] ?? '',
    );
  }
}