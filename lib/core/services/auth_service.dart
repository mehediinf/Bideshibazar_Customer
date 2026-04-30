// lib/core/services/auth_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../network/api_constants.dart';
import '../../data/models/request/login_request.dart';
import '../../data/models/response/login_response.dart';

class AuthService {
  Future<Map<String, dynamic>> login(LoginRequest request) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(data);
        return {
          'success': true,
          'data': loginResponse,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
      };
    }
  }
}