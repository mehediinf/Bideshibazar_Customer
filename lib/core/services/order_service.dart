// lib/core/services/order_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../network/api_constants.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_detail_model.dart';
import '../../data/models/delivery_status_model.dart';

class OrderService {
  Future<List<Order>> getUserOrders(String token) async {
    try {
      final url = '${ApiConstants.baseUrl}user/orders';

      if (token.isNotEmpty) {
        print(
          '│ Token preview: ${token.substring(0, token.length > 50 ? 50 : token.length)}...',
        );
      }

      if (token.isEmpty) {
        throw Exception('Authentication token is required');
      }
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data.containsKey("message")) {
          print('│ Message: ${data["message"]}');
        }
        if (data['orders'] == null) {
          return [];
        }

        final List<dynamic> ordersJson = data['orders'] as List<dynamic>;

        if (ordersJson.isEmpty) {
          return [];
        }

        final List<Order> orders = [];

        for (var i = 0; i < ordersJson.length; i++) {
          try {
            final orderJson = ordersJson[i] as Map<String, dynamic>;

            final order = Order.fromJson(orderJson);
            orders.add(order);
          } catch (e, stack) {
            final stackLines = stack.toString().split('\n');
            for (var line in stackLines.take(3)) {
              print('│         $line');
            }
          }
        }

        if (orders.isNotEmpty) {
          for (var order in orders) {
            print(
              '   • ${order.code} - ${order.shopName} - €${order.total} - ${order.status}',
            );
          }
        }

        return orders;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Orders endpoint not found');
      } else if (response.statusCode == 500) {
        throw Exception('Server error: Please try again later');
      } else {
        throw Exception('Failed to load orders: HTTP ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelOrder(int orderId, String token) async {
    try {
      final url = '${ApiConstants.baseUrl}user/cancel/order/$orderId';

      print('\n Sending HTTP GET request...');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Order not found');
      } else {
        throw Exception('Failed to cancel order: HTTP ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderDetail> getOrderDetails(int orderId, String token) async {
    try {
      final url = '${ApiConstants.baseUrl}user/order/details/$orderId';

      print('\n Sending HTTP GET request...');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final rawOrder = data['orderDetails'] ?? data['order'];

        if (rawOrder is! Map<String, dynamic>) {
          throw Exception('Order data not found');
        }

        final orderDetail = OrderDetail.fromJson(rawOrder);

        return orderDetail;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else if (response.statusCode == 404) {
        throw Exception('Order not found');
      } else {
        throw Exception('Failed to load order details: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<String> getPaymentUrl(String uuid, String token) async {
    try {
      final url = '${ApiConstants.baseUrl}user/order/payment/$uuid';

      print('\nSending HTTP GET request...');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final checkoutUrl = data['checkout_url']?.toString() ?? '';
        return checkoutUrl;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to get payment URL: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateOrderItem(
    int orderId,
    int itemId,
    int quantity,
    String token,
  ) async {
    try {
      final url = '${ApiConstants.baseUrl}user/update/order/$orderId';

      final body = json.encode({'item_id': itemId, 'quantity': quantity});

      print('\n Sending HTTP POST request...');
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(' Update successful');
        print('Response: ${response.body}');

        String? newTotal;
        if (data.containsKey('order_total')) {
          newTotal = data['order_total']?.toString();
        } else if (data.containsKey('order') && data['order'] != null) {
          newTotal = data['order']['total']?.toString();
        }

        return {'success': true, 'newTotal': newTotal};
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to update item: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> deleteOrderItem(
    int orderId,
    int itemId,
    String token,
  ) async {
    try {
      final url =
          '${ApiConstants.baseUrl}user/remove/order/item/$orderId?item_id=$itemId';

      final response = await http.delete(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        String? newTotal;
        if (data.containsKey('order_total') && data['order_total'] != null) {
          newTotal = data['order_total']?.toString();
        } else if (data.containsKey('order') && data['order'] != null) {
          newTotal = data['order']['total']?.toString();
        }

        return {'success': true, 'newTotal': newTotal ?? '0.00'};
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized: Please login again');
      } else {
        throw Exception('Failed to delete item: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<DeliveryStatusModel> getDeliveryDetails(
    int orderId,
    String token,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}user/delivery/details/$orderId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        return DeliveryStatusModel.fromJson(jsonData);
      } else {
        throw Exception(
          'Failed to load delivery details: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
