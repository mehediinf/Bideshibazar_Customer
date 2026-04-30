// lib/presentation/order_history/order_history_view.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/firebase_messaging_service.dart';
import '../../core/services/order_service.dart';
import '../../core/services/order_stream_service.dart';
import '../../core/utils/app_error_helper.dart';
import '../../data/models/order_model.dart';
import 'package:bideshibazar/presentation/order_detail/order_detail_view.dart';
import '../delivery_status/delivery_status_view.dart';

class OrderHistoryView extends StatefulWidget {
  const OrderHistoryView({super.key});

  @override
  State<OrderHistoryView> createState() => _OrderHistoryViewState();
}

class _OrderHistoryViewState extends State<OrderHistoryView>
    with WidgetsBindingObserver {
  final OrderService _orderService = OrderService();
  final OrderStreamService _streamService = OrderStreamService();

  List<Order>? _orders;
  bool _isLoading = true;
  String? _error;
  String? _currentToken;
  StreamSubscription<List<Order>>? _ordersSubscription;
  StreamSubscription<Map<String, dynamic>>? _orderRefreshSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _debugTokenInfo();
      await _initializeStream();
      _bindPushRefresh();
    });
  }

  // Separate debug method
  Future<void> _debugTokenInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      debugPrint(' OrderHistoryView Debug:');
      debugPrint(
        'Token in SharedPrefs: ${token != null ? ' ${token.substring(0, min(20, token.length))}...' : ' NULL'}',
      );
      debugPrint('UserProvider isLoggedIn: ${userProvider.isLoggedIn}');
      debugPrint(
        'UserProvider token: ${userProvider.token != null ? ' ${userProvider.token!.substring(0, min(20, userProvider.token!.length))}...' : '❌ NULL'}',
      );
      debugPrint('UserProvider userId: ${userProvider.userId}');
    } catch (e) {
      debugPrint(' Debug error: $e');
    }
  }

  Future<void> _initializeStream() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    debugPrint('[OrderHistoryView] Initializing stream...');
    debugPrint('   UserProvider.isLoggedIn: ${userProvider.isLoggedIn}');
    debugPrint(
      '   UserProvider.token: ${userProvider.token != null ? 'EXISTS' : 'NULL'}',
    );

    if (userProvider.token == null || userProvider.token!.isEmpty) {
      debugPrint(' Token empty in UserProvider, attempting reload...');

      try {
        await userProvider.loadUserData();

        if (userProvider.token != null && userProvider.token!.isNotEmpty) {
          debugPrint(' Token loaded successfully after reload');
          _startPolling(userProvider.token!);
        } else {
          // Still no token - user really not logged in
          debugPrint(' Token still empty after reload - user not logged in');
          if (mounted) {
            setState(() {
              _error = 'Please log in to view your orders.';
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        debugPrint(' Error loading user data: $e');
        if (mounted) {
          setState(() {
            _error = 'Please log in to view your orders.';
            _isLoading = false;
          });
        }
      }
      return;
    }

    _startPolling(userProvider.token!);
  }

  void _startPolling(String token) {
    _currentToken = token;
    debugPrint(
      ' [OrderHistoryView] Starting polling with token: ${token.substring(0, min(50, token.length))}...',
    );

    _ordersSubscription?.cancel();

    // Start auto-polling
    _streamService.startOrdersPolling(token);

    // Listen to stream
    _ordersSubscription = _streamService.ordersStream.listen(
      (orders) {
        if (mounted) {
          setState(() {
            _orders = orders;
            _isLoading = false;
            _error = null;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = AppErrorHelper.toUserMessage(error);
            _isLoading = false;
          });
        }
      },
    );
  }

  void _bindPushRefresh() {
    try {
      final fcmService = context.read<FirebaseMessagingService>();
      _orderRefreshSubscription?.cancel();
      _orderRefreshSubscription = fcmService.orderRefreshStream.listen((
        data,
      ) async {
        debugPrint(
          ' [OrderHistoryView] Push notification received, refreshing orders...',
        );
        debugPrint(' [OrderHistoryView] Notification payload: $data');
        await _refreshOrdersSilently();
      });
    } catch (e) {
      debugPrint(' [OrderHistoryView] FCM service not available: $e');
    }
  }

  Future<void> _refreshOrdersSilently() async {
    if (_currentToken == null || _currentToken!.isEmpty) {
      return;
    }

    try {
      await _streamService.refreshOrders();
    } catch (e) {
      debugPrint(' [OrderHistoryView] Silent refresh failed: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshOrdersSilently();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ordersSubscription?.cancel();
    _orderRefreshSubscription?.cancel();
    _streamService.stopOrdersPolling();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await _streamService.refreshOrders();
  }

  // Navigate to home - always go to /home route
  void _navigateToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _navigateToHome();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _navigateToHome,
          ),
          title: const Text(
            'Order History',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Row(
                  children: [
                    Icon(Icons.sync, size: 16, color: Colors.green[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Auto',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      // Check if error is due to missing token
      final isAuthError =
          _error!.contains('Authentication') ||
          _error!.contains('token') ||
          _error!.contains('login');

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isAuthError ? Icons.lock_outline : Icons.error_outline,
              size: 80,
              color: isAuthError ? Colors.orange[300] : Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              isAuthError ? 'Login Required' : 'Failed to load orders',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                isAuthError ? 'Please login to view your orders' : _error!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            if (isAuthError)
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate to login/welcome page
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/welcome', (route) => false);
                },
                icon: const Icon(Icons.login),
                label: const Text('Go to Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              )
            else
              TextButton(onPressed: _onRefresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_orders == null || _orders!.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders!.length,
        itemBuilder: (context, index) {
          return _buildOrderCard(_orders![index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Code and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.code,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                _buildPaymentStatus(order),
              ],
            ),
            const SizedBox(height: 12),

            // Date and Address
            Row(
              children: [
                Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  order.date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.address,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Total Amount Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL AMOUNT',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '€${order.total}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                    ],
                  ),
                  if (order.shopName.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'SHOP',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.shopName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatus(Order order) {
    final statusLower = order.status.toLowerCase();

    String statusText;
    Color statusColor;

    switch (statusLower) {
      case 'accept_payment_pending':
      case 'hold':
      case 'accept_failed':
        statusText = 'Payment Pending';
        statusColor = const Color(0xFFE53935);
        break;

      case 'accept_paid':
        statusText = 'Paid';
        statusColor = const Color(0xFF43A047);
        break;

      case 'approved':
        statusText = 'Waiting for Pickup';
        statusColor = const Color(0xFFFFA000);
        break;

      case 'pickup':
        statusText = 'Ready for Pickup';
        statusColor = const Color(0xFF43A047);
        break;

      case 'transit':
        statusText = 'In Transit';
        statusColor = const Color(0xFF3949AB);
        break;

      case 'delivered':
        statusText = 'Delivered';
        statusColor = const Color(0xFF4CAF50);
        break;

      case 'delivery_failed':
      case 'returned':
        statusText = 'Failed';
        statusColor = const Color(0xFFD32F2F);
        break;

      case 'cancelled':
        statusText = 'Cancelled';
        statusColor = const Color(0xFF757575);
        break;

      default:
        statusText = 'Processing';
        statusColor = const Color(0xFF1976D2);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 0.5),
      ),
      child: Text(
        statusText.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: statusColor,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Order order) {
    final statusLower = order.status.toLowerCase();

    final showCancelButton =
        statusLower == 'processing' ||
        statusLower == 'accept_payment_pending' ||
        statusLower == 'hold';

    final showDeliveryButton =
        statusLower == 'approved' ||
        statusLower == 'pickup' ||
        statusLower == 'transit' ||
        statusLower == 'delivered' ||
        statusLower == 'delivery_failed' ||
        statusLower == 'returned';

    final showPaymentButton =
        statusLower == 'accept_payment_pending' ||
        statusLower == 'hold' ||
        statusLower == 'accept_failed';

    return Row(
      children: [
        _buildGradientButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailView(
                  orderId: order.id,
                  orderUuid: order.uuid,
                ),
              ),
            );
          },
          gradient: const LinearGradient(
            colors: [Color(0xFF607D8B), Color(0xFF455A64)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shadowColor: Colors.blueGrey,
          icon: Icons.visibility_outlined,
          label: 'Detail',
          textColor: Colors.white,
        ),
        const Spacer(),
        if (showPaymentButton)
          _buildGradientButton(
            onPressed: () {
              if (order.uuid.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error! Invalid payment link.'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailView(
                      orderId: order.id,
                      orderUuid: order.uuid,
                    ),
                  ),
                );
              }
            },
            gradient: const LinearGradient(
              colors: [Color(0xFFFFA000), Color(0xFFFF8F00)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shadowColor: Colors.orange,
            icon: Icons.payment,
            label: 'Pay',
            textColor: Colors.white,
          ),
        if (showCancelButton) ...[
          if (showPaymentButton) const SizedBox(width: 8),
          _buildGradientButton(
            onPressed: () => _showCancelOrderDialog(order),
            gradient: const LinearGradient(
              colors: [Color(0xFFEF5350), Color(0xFFD32F2F)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shadowColor: Colors.red,
            icon: Icons.close_rounded,
            label: 'Cancel',
            textColor: Colors.white,
          ),
        ],
        if (showDeliveryButton)
          _buildGradientButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DeliveryStatusView(orderId: order.id),
                ),
              );
            },
            gradient: const LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shadowColor: Colors.blue,
            icon: Icons.local_shipping_outlined,
            label: 'Track',
            textColor: Colors.white,
          ),
      ],
    );
  }

  // Custom gradient button widget for professional look
  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required Gradient gradient,
    required Color shadowColor,
    required IconData icon,
    required String label,
    required Color textColor,
    bool isFullWidth = false,
  }) {
    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: shadowColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: textColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Orders Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your order history will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  void _showCancelOrderDialog(Order order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cancel Order'),
          content: Text('Are you sure you want to cancel order ${order.code}?'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  final userProvider = Provider.of<UserProvider>(
                    context,
                    listen: false,
                  );
                  await _orderService.cancelOrder(
                    order.id,
                    userProvider.token ?? '',
                  );

                  if (mounted) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order cancelled successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Auto-refresh will handle the update
                    await _streamService.refreshOrders();
                  }
                } catch (e) {
                  if (mounted) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to cancel order: ${e.toString()}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
              child: const Text('Yes, Cancel'),
            ),
          ],
        );
      },
    );
  }
}
