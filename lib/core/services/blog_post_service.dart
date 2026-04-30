import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/models/blog_post_model.dart';
import '../network/api_constants.dart';
import '../utils/shared_prefs_helper.dart';

class BlogPostService {
  Future<BlogPostsResponse> fetchBlogPosts() async {
    final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.blogPosts}');
    final token = await SharedPrefsHelper.getToken();

    debugPrint('Fetching blog posts from: $url');

    final headers = {
      ...ApiConstants.defaultHeaders,
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch blog posts: ${response.statusCode}');
    }

    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    return BlogPostsResponse.fromJson(jsonData);
  }

  Future<BlogCommentModel> postComment({
    required String slug,
    required String authorName,
    required String authorEmail,
    required String content,
  }) async {
    final url = Uri.parse('${ApiConstants.baseUrl}blog/posts/$slug/comments');

    final response = await http.post(
      url,
      headers: ApiConstants.defaultHeaders,
      body: json.encode({
        'author_name': authorName,
        'author_email': authorEmail,
        'content': content,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to post comment: ${response.statusCode}');
    }

    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    return BlogCommentModel.fromJson(
      jsonData['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<BlogPostDetailsModel> fetchBlogPostDetails(String slug) async {
    final token = await SharedPrefsHelper.getToken();
    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.blogPosts}/$slug',
    );

    final headers = {
      ...ApiConstants.defaultHeaders,
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to fetch blog post details: ${response.statusCode}',
      );
    }

    final jsonData = json.decode(response.body) as Map<String, dynamic>;
    return BlogPostDetailsModel.fromJson(
      jsonData['data'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<void> likePost(String slug) async {
    final token = await SharedPrefsHelper.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please log in to like this post.');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}blog/posts/$slug/like');
    debugPrint('Liking blog post: $url');

    final response = await http.post(
      url,
      headers: {
        ...ApiConstants.defaultHeaders,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to like post: ${response.statusCode}');
    }
  }

  Future<void> unlikePost(String slug) async {
    final token = await SharedPrefsHelper.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please log in to unlike this post.');
    }

    final url = Uri.parse('${ApiConstants.baseUrl}blog/posts/$slug/like');
    debugPrint('Unliking blog post: $url');

    final response = await http.delete(
      url,
      headers: {
        ...ApiConstants.defaultHeaders,
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to unlike post: ${response.statusCode}');
    }
  }
}
