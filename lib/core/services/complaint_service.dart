import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/complaint_models.dart';
import '../network/api_constants.dart';
import '../utils/shared_prefs_helper.dart';

class ComplaintService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: const {'Accept': 'application/json'},
    ),
  );

  Future<Options> _authorizedOptions() async {
    final token = await SharedPrefsHelper.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please log in to continue.');
    }

    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<
    ({List<ComplaintLookupItem> categories, List<ComplaintLookupItem> statuses})
  >
  getComplaintLookups() async {
    final response = await _dio.get(
      ApiConstants.complaintCategories,
      options: await _authorizedOptions(),
    );

    final data = response.data as Map<String, dynamic>;
    final categories = (data['categories'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ComplaintLookupItem.fromJson)
        .toList();
    final statuses = (data['statuses'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ComplaintLookupItem.fromJson)
        .toList();

    return (categories: categories, statuses: statuses);
  }

  Future<List<EligibleComplaintOrder>> getEligibleOrders() async {
    final response = await _dio.get(
      ApiConstants.complaintEligibleOrders,
      options: await _authorizedOptions(),
    );

    final data = response.data as Map<String, dynamic>;
    return (data['orders'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(EligibleComplaintOrder.fromJson)
        .toList();
  }

  Future<List<ComplaintHistoryItem>> getComplaints() async {
    final response = await _dio.get(
      ApiConstants.complaints,
      options: await _authorizedOptions(),
    );

    final data = response.data as Map<String, dynamic>;
    return (data['complaints'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ComplaintHistoryItem.fromJson)
        .toList();
  }

  Future<String> submitComplaint({
    required int orderId,
    required String category,
    required String complaintText,
    String? conditionalDetail,
    File? photo,
  }) async {
    final payload = <String, dynamic>{
      'order_id': orderId,
      'category': category,
      'complaint_text': complaintText,
      'conditional_detail': conditionalDetail ?? '',
    };

    if (photo != null) {
      payload['photos[]'] = await MultipartFile.fromFile(
        photo.path,
        filename: photo.path.split('/').last,
      );
    } else {
      payload['photos'] = <String>[];
    }

    final formData = FormData.fromMap(payload);

    debugPrint('[ComplaintService] Submitting complaint...');
    debugPrint('[ComplaintService] Endpoint: ${ApiConstants.complaints}');
    debugPrint('[ComplaintService] order_id: $orderId');
    debugPrint('[ComplaintService] category: $category');
    debugPrint('[ComplaintService] complaint_text: $complaintText');
    debugPrint(
      '[ComplaintService] conditional_detail: ${conditionalDetail ?? ''}',
    );
    debugPrint(
      '[ComplaintService] photo attached: ${photo != null ? photo.path.split('/').last : 'no'}',
    );
    debugPrint('[ComplaintService] payload keys: ${payload.keys.join(', ')}');

    try {
      final response = await _dio.post(
        ApiConstants.complaints,
        data: formData,
        options: (await _authorizedOptions()).copyWith(
          contentType: 'multipart/form-data',
        ),
      );

      debugPrint('[ComplaintService] Response status: ${response.statusCode}');
      debugPrint('[ComplaintService] Response body: ${response.data}');

      final data = response.data as Map<String, dynamic>;
      return data['message']?.toString() ?? 'Complaint submitted successfully.';
    } on DioException catch (error) {
      debugPrint(
        '[ComplaintService] Error status: ${error.response?.statusCode}',
      );
      debugPrint('[ComplaintService] Error body: ${error.response?.data}');
      debugPrint('[ComplaintService] Error message: ${error.message}');
      rethrow;
    }
  }
}
