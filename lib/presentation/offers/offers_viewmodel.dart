//lib/presentation/offers/offers_viewmodel.dart

import 'package:flutter/material.dart';
import '../../core/utils/app_error_helper.dart';
import '../../data/models/offer_model.dart';
import '../../data/repositories/offer_repository.dart';

class OffersViewModel extends ChangeNotifier {
  final OfferRepository _repository = OfferRepository();

  List<OfferModel> _offers = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<OfferModel> get offers => _offers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchOffers() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _repository.fetchOffers();
      _offers = response.offers;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = AppErrorHelper.toUserMessage(e);
      _isLoading = false;
      notifyListeners();
    }
  }

  ProductModel? getFirstProduct(OfferModel offer) {
    return offer.products.isNotEmpty ? offer.products.first : null;
  }
}
