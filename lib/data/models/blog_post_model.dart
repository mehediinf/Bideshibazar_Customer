class BlogPostModel {
  final int id;
  final String title;
  final String slug;
  final String summary;
  final String author;
  final String publishedAt;
  final String timeAgo;
  final int commentsCount;
  final int likesCount;
  final bool isLiked;
  final BlogCategory category;
  final BlogSeller seller;
  final List<BlogImage> images;

  const BlogPostModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.summary,
    required this.author,
    required this.publishedAt,
    required this.timeAgo,
    required this.commentsCount,
    required this.likesCount,
    required this.isLiked,
    required this.category,
    required this.seller,
    required this.images,
  });

  String get coverImage => images.isNotEmpty ? images.first.url : '';

  factory BlogPostModel.fromJson(Map<String, dynamic> json) {
    return BlogPostModel(
      id: _toInt(json['id']),
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      publishedAt: json['published_at']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
      commentsCount: _toInt(json['comments_count']),
      likesCount: _toInt(json['likes_count']),
      isLiked: json['is_liked'] == true || json['is_liked'] == 1,
      category: BlogCategory.fromJson(
        json['category'] as Map<String, dynamic>? ?? const {},
      ),
      seller: BlogSeller.fromJson(
        json['seller'] as Map<String, dynamic>? ?? const {},
      ),
      images: (json['images'] as List<dynamic>? ?? const [])
          .map((image) => BlogImage.fromJson(image as Map<String, dynamic>))
          .toList(),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }
}

class BlogCategory {
  final int id;
  final String name;
  final String slug;

  const BlogCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory BlogCategory.fromJson(Map<String, dynamic> json) {
    return BlogCategory(
      id: BlogPostModel._toInt(json['id']),
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
    );
  }
}

class BlogSeller {
  final int id;
  final String name;

  const BlogSeller({required this.id, required this.name});

  factory BlogSeller.fromJson(Map<String, dynamic> json) {
    return BlogSeller(
      id: BlogPostModel._toInt(json['id']),
      name: json['name']?.toString() ?? '',
    );
  }
}

class BlogImage {
  final int id;
  final String url;
  final int sortOrder;

  const BlogImage({
    required this.id,
    required this.url,
    required this.sortOrder,
  });

  factory BlogImage.fromJson(Map<String, dynamic> json) {
    return BlogImage(
      id: BlogPostModel._toInt(json['id']),
      url: json['url']?.toString() ?? '',
      sortOrder: BlogPostModel._toInt(json['sort_order']),
    );
  }
}

class BlogPostsResponse {
  final String status;
  final String message;
  final List<BlogPostModel> posts;
  final BlogPagination pagination;

  const BlogPostsResponse({
    required this.status,
    required this.message,
    required this.posts,
    required this.pagination,
  });

  factory BlogPostsResponse.fromJson(Map<String, dynamic> json) {
    return BlogPostsResponse(
      status: json['status']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      posts: (json['data'] as List<dynamic>? ?? const [])
          .map((item) => BlogPostModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      pagination: BlogPagination.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class BlogPagination {
  final int total;
  final int perPage;
  final int currentPage;
  final int lastPage;
  final int from;
  final int to;

  const BlogPagination({
    required this.total,
    required this.perPage,
    required this.currentPage,
    required this.lastPage,
    required this.from,
    required this.to,
  });

  factory BlogPagination.fromJson(Map<String, dynamic> json) {
    return BlogPagination(
      total: BlogPostModel._toInt(json['total']),
      perPage: BlogPostModel._toInt(json['per_page']),
      currentPage: BlogPostModel._toInt(json['current_page']),
      lastPage: BlogPostModel._toInt(json['last_page']),
      from: BlogPostModel._toInt(json['from']),
      to: BlogPostModel._toInt(json['to']),
    );
  }
}

class BlogCommentModel {
  final int id;
  final String authorName;
  final String authorEmail;
  final String content;
  final String publishedAt;
  final String createdAt;
  final String timeAgo;

  const BlogCommentModel({
    required this.id,
    required this.authorName,
    required this.authorEmail,
    required this.content,
    required this.publishedAt,
    this.createdAt = '',
    required this.timeAgo,
  });

  factory BlogCommentModel.fromJson(Map<String, dynamic> json) {
    return BlogCommentModel(
      id: BlogPostModel._toInt(json['id']),
      authorName: json['author_name']?.toString() ?? '',
      authorEmail: json['author_email']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      publishedAt: json['published_at']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
    );
  }
}

class BlogPostDetailsModel {
  final int id;
  final String title;
  final String slug;
  final String summary;
  final String content;
  final String author;
  final String publishedAt;
  final String timeAgo;
  final int commentsCount;
  final int likesCount;
  final bool isLiked;
  final BlogCategory category;
  final BlogSeller seller;
  final List<BlogImage> images;
  final List<BlogCommentModel> comments;

  const BlogPostDetailsModel({
    required this.id,
    required this.title,
    required this.slug,
    required this.summary,
    required this.content,
    required this.author,
    required this.publishedAt,
    required this.timeAgo,
    required this.commentsCount,
    required this.likesCount,
    required this.isLiked,
    required this.category,
    required this.seller,
    required this.images,
    required this.comments,
  });

  String get coverImage => images.isNotEmpty ? images.first.url : '';

  factory BlogPostDetailsModel.fromJson(Map<String, dynamic> json) {
    return BlogPostDetailsModel(
      id: BlogPostModel._toInt(json['id']),
      title: json['title']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      author: json['author']?.toString() ?? '',
      publishedAt: json['published_at']?.toString() ?? '',
      timeAgo: json['time_ago']?.toString() ?? '',
      commentsCount: BlogPostModel._toInt(json['comments_count']),
      likesCount: BlogPostModel._toInt(json['likes_count']),
      isLiked: json['is_liked'] == true || json['is_liked'] == 1,
      category: BlogCategory.fromJson(
        json['category'] as Map<String, dynamic>? ?? const {},
      ),
      seller: BlogSeller.fromJson(
        json['seller'] as Map<String, dynamic>? ?? const {},
      ),
      images: (json['images'] as List<dynamic>? ?? const [])
          .map((image) => BlogImage.fromJson(image as Map<String, dynamic>))
          .toList(),
      comments: (json['comments'] as List<dynamic>? ?? const [])
          .map(
            (item) => BlogCommentModel.fromJson(item as Map<String, dynamic>),
      )
          .toList(),
    );
  }
}