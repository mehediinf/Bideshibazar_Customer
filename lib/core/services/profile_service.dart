// lib/core/services/profile_service.dart

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import '../network/api_constants.dart';
import '../utils/shared_prefs_helper.dart';

class ProfileService {
  Future<Map<String, dynamic>> updateProfileImage(File imageFile) async {
    try {
      final token = await SharedPrefsHelper.getToken();

      if (token == null) {
        return {
          'success': false,
          'message': 'Please login first',
        };
      }

      // Check if file exists
      if (!await imageFile.exists()) {
        return {
          'success': false,
          'message': 'Image file not found',
        };
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateProfile}');

      var request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Content-Type'] = 'application/json';
      request.headers['Accept'] = 'application/json';

      // Determine content type based on file extension
      String fileName = imageFile.path.split('/').last;
      String? mimeType;

      if (fileName.toLowerCase().endsWith('.jpg') || fileName.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else if (fileName.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (fileName.toLowerCase().endsWith('.heic')) {
        mimeType = 'image/heic';
      } else {
        mimeType = 'image/jpeg'; // default
      }

      // Add image file with proper content type
      request.files.add(
        await http.MultipartFile.fromPath(
          'profile_image',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      print('Uploading image: $fileName, MIME: $mimeType, Size: ${await imageFile.length()} bytes');

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout');
        },
      );

      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Profile updated successfully',
          'user': data['user'],
        };
      } else {
        final error = json.decode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      print('Profile update error: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}