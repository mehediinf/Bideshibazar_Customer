// lib/presentation/store/store_viewmodel.dart

import 'package:flutter/material.dart';
import '../../core/network/api_service.dart';
import '../../core/utils/app_error_helper.dart';
import '../../data/models/store_model.dart';
import 'dart:developer' as developer;

class StoreViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<StoreModel> _stores = [];
  List<StoreModel> get stores => _stores;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int _selectedCategory = 0;
  int get selectedCategory => _selectedCategory;

  final List<String> _categories = ['Grocery', 'Fashion', 'Air Tickets'];
  List<String> get categories => _categories;

  StoreViewModel() {
    developer.log('StoreViewModel initialized');
    fetchStores();
  }

  void changeCategory(int index) {
    developer.log('Category changed to: ${_categories[index]}');
    _selectedCategory = index;
    notifyListeners();
  }

  Future<void> fetchStores() async {
    developer.log('Fetching stores...');

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.getStores();

      developer.log('API Response received');
      developer.log('Response type: ${response.runtimeType}');
      developer.log('Response keys: ${response.keys.toList()}');

      if (response['stores'] != null) {
        developer.log('Stores data found');

        final storesList = response['stores'] as List;
        developer.log('Total stores in response: ${storesList.length}');

        _stores = storesList
            .map((json) {
          try {
            return StoreModel.fromJson(json);
          } catch (e) {
            developer.log('Error parsing store: $e');
            developer.log('Problematic JSON: $json');
            return null;
          }
        })
            .where((store) => store != null && store.status == 'active')
            .cast<StoreModel>()
            .toList();

        developer.log('Active stores parsed: ${_stores.length}');

        // Sort by sort_order
        _stores.sort((a, b) => (a.sortOrder ?? 999).compareTo(b.sortOrder ?? 999));

        developer.log('Stores sorted successfully');
        _errorMessage = null;
      } else {
        developer.log(' No stores key in response');
        _errorMessage = 'No stores data available';
      }
    } catch (e, stackTrace) {
      developer.log('Error in fetchStores: $e');
      developer.log('Stack trace: $stackTrace');
      _errorMessage = AppErrorHelper.toUserMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();

      developer.log('Fetch complete - Loading: $_isLoading, Error: $_errorMessage, Stores: ${_stores.length}');
    }
  }

  Future<void> refreshStores() async {
    developer.log('Refreshing stores...');
    await fetchStores();
  }
}
