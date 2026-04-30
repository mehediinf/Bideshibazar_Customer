// lib/core/services/order_stream_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_detail_model.dart';
import 'order_service.dart';

class OrderStreamService {
  static final OrderStreamService _instance = OrderStreamService._internal();
  factory OrderStreamService() => _instance;
  OrderStreamService._internal();

  final OrderService _orderService = OrderService();

  final _ordersController = StreamController<List<Order>>.broadcast();
  final _orderDetailController = StreamController<OrderDetail>.broadcast();

  Timer? _ordersPollingTimer;
  Timer? _orderDetailPollingTimer;

  String? _currentToken;
  int? _currentOrderId;
  bool _isFetchingOrders = false;
  bool _isFetchingOrderDetail = false;

  static const int _ordersPollingInterval = 10;
  static const int _orderDetailPollingInterval = 5;

  Stream<List<Order>> get ordersStream => _ordersController.stream;
  Stream<OrderDetail> get orderDetailStream => _orderDetailController.stream;

  void startOrdersPolling(String token) {
    debugPrint(' [OrderStreamService] Starting orders polling...');
    _currentToken = token;

    stopOrdersPolling();

    _fetchOrders();

    _ordersPollingTimer = Timer.periodic(
      const Duration(seconds: _ordersPollingInterval),
      (_) => _fetchOrders(),
    );
  }

  void stopOrdersPolling() {
    debugPrint(' [OrderStreamService] Stopping orders polling...');
    _ordersPollingTimer?.cancel();
    _ordersPollingTimer = null;
  }

  void startOrderDetailPolling(int orderId, String token) {
    debugPrint(
      ' [OrderStreamService] Starting order detail polling for ID: $orderId',
    );
    _currentOrderId = orderId;
    _currentToken = token;

    stopOrderDetailPolling();

    _fetchOrderDetail();

    _orderDetailPollingTimer = Timer.periodic(
      const Duration(seconds: _orderDetailPollingInterval),
      (_) => _fetchOrderDetail(),
    );
  }

  void stopOrderDetailPolling() {
    debugPrint(' [OrderStreamService] Stopping order detail polling...');
    _orderDetailPollingTimer?.cancel();
    _orderDetailPollingTimer = null;
  }

  Future<void> _fetchOrders() async {
    if (_currentToken == null || _isFetchingOrders) return;

    _isFetchingOrders = true;

    try {
      debugPrint(' [OrderStreamService] Fetching orders...');
      final orders = await _orderService.getUserOrders(_currentToken!);

      if (!_ordersController.isClosed) {
        _ordersController.add(orders);
        debugPrint(
          ' [OrderStreamService] Orders updated: ${orders.length} items',
        );
      }
    } catch (e) {
      debugPrint(' [OrderStreamService] Error fetching orders: $e');
      if (!_ordersController.isClosed) {
        _ordersController.addError(e);
      }
    } finally {
      _isFetchingOrders = false;
    }
  }

  Future<void> _fetchOrderDetail() async {
    if (_currentOrderId == null ||
        _currentToken == null ||
        _isFetchingOrderDetail) {
      return;
    }

    _isFetchingOrderDetail = true;

    try {
      debugPrint(' [OrderStreamService] Fetching order detail...');
      final orderDetail = await _orderService.getOrderDetails(
        _currentOrderId!,
        _currentToken!,
      );

      if (!_orderDetailController.isClosed) {
        _orderDetailController.add(orderDetail);
        debugPrint(' [OrderStreamService] Order detail updated');
      }
    } catch (e) {
      debugPrint(' [OrderStreamService] Error fetching order detail: $e');
      if (!_orderDetailController.isClosed) {
        _orderDetailController.addError(e);
      }
    } finally {
      _isFetchingOrderDetail = false;
    }
  }

  Future<void> refreshOrders() async {
    debugPrint(' [OrderStreamService] Manual refresh orders');
    await _fetchOrders();
  }

  Future<void> refreshOrderDetail() async {
    debugPrint(' [OrderStreamService] Manual refresh order detail');
    await _fetchOrderDetail();
  }

  void dispose() {
    debugPrint('️ [OrderStreamService] Disposing...');
    stopOrdersPolling();
    stopOrderDetailPolling();
    _ordersController.close();
    _orderDetailController.close();
  }
}
