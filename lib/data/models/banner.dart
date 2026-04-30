class BannerItem {
  final int id;
  final String imageUrl;
  final String? link;

  BannerItem({
    required this.id,
    required this.imageUrl,
    this.link,
  });

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] ?? 0,
      imageUrl: json['image_url'] ?? '',
      link: json['link'],
    );
  }
}