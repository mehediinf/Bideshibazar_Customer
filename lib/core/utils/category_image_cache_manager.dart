import '../network/api_constants.dart';

class CategoryImageCacheManager {
  static String? resolveUrl(String? imagePath) {
    if (imagePath == null || imagePath.trim().isEmpty) return null;

    final normalizedPath = imagePath.trim().replaceAll('\\', '/');
    final url = ApiConstants.getImageUrl(normalizedPath);
    return url.isEmpty ? null : url;
  }
}
