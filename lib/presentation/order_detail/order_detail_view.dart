import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/network/api_constants.dart';
import '../../core/utils/cart_manager.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/order_service.dart';
import '../../core/utils/app_error_helper.dart';
import '../../data/models/order_model.dart';
import '../../data/models/order_detail_model.dart';
import '../payment/payment_webview.dart';

class OrderDetailView extends StatefulWidget {
  final int orderId;
  final String orderUuid;
  final Order? order;

  const OrderDetailView({
    super.key,
    required this.orderId,
    required this.orderUuid,
    this.order,
  });

  @override
  State<OrderDetailView> createState() => _OrderDetailViewState();
}

class _OrderDetailViewState extends State<OrderDetailView> {
  // Theme colors based on project palette
  static const Color _accent = Color(0xFF2E7D32); // Deep Green
  static const Color _surface = Color(0xFFF9FBF9);
  static const Color _itemBorder = Color(0xFFE8F1E8);
  static const Color _ink = Color(0xFF1B3022);
  static const Color _muted = Color(0xFF718E7A);
  static const Color _priceBlue = Color(0xFF2C5E85);
  static const Color _softGreen = Color(0xFFE8F5E9);
  static const Color _danger = Color(0xFFD32F2F);
  static const Color _success = Color(0xFF388E3C);
  static const Color _pageBg = Color(0xFFF7FBF8);
  static const Color _line = Color(0xFFE1ECE5);
  static const Color _primary = Color(0xFF2E7D32);
  static const Color _primaryDark = Color(0xFF1F5A24);
  static const Color _softAmber = Color(0xFFFFF3D6);
  static const Color _softRed = Color(0xFFFFEBEE);
  static const Color _itemBg = Color(0xFFFFFFFF);
  static const List<Color> _primaryGrad = [
    Color(0xFF4CAF50),
    Color(0xFF2E7D32),
  ];
  static const List<Color> _accentGrad = [Color(0xFF26A69A), Color(0xFF00897B)];

  final OrderService _orderService = OrderService();
  late Future<OrderDetail> _orderDetailFuture;
  late String _currentUuid;
  bool _isLoading = false;
  bool _isCustomerExpanded = false;

  @override
  void initState() {
    super.initState();
    _currentUuid = widget.orderUuid;
    _loadOrderDetail();
  }

  void _loadOrderDetail() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _orderDetailFuture = _orderService.getOrderDetails(
        widget.orderId,
        userProvider.token ?? '',
      );
    });
  }

  String _normalizeStatus(String status) {
    final normalized = status
        .trim()
        .toLowerCase()
        .replaceAll('&', 'and')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    switch (normalized) {
      case 'accept_payment_pending':
      case 'accept_payment':
      case 'payment_pending':
        return 'accept_payment_pending';
      default:
        return normalized;
    }
  }

  bool _canEditOrder(String status) {
    switch (_normalizeStatus(status)) {
      case 'accept_payment_pending':
      case 'hold':
      case 'accept_failed':
      case 'processing':
        return true;
      default:
        return false;
    }
  }

  bool _showPaymentButton(String status) {
    switch (_normalizeStatus(status)) {
      case 'accept_payment_pending':
      case 'hold':
      case 'accept_failed':
        return true;
      default:
        return false;
    }
  }

  Future<void> _loadPaymentUrl(String uuid) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final checkoutUrl = await _orderService.getPaymentUrl(
        uuid,
        userProvider.token ?? '',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (checkoutUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment link not found!'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebView(checkoutUrl: checkoutUrl),
        ),
      );

      if (!mounted) return;

      if (result == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadOrderDetail();
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppErrorHelper.toUserMessage(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openExternalUrl(String url, String label) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorHelper.toUserMessage(
              null,
              fallback: 'This $label link is not valid.',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!mounted) return;

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppErrorHelper.toUserMessage(
              null,
              fallback: 'This $label could not be opened right now.',
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _ink,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _line, height: 1),
        ),
      ),
      body: FutureBuilder<OrderDetail>(
        future: _orderDetailFuture,
        builder: (context, snapshot) {
          Widget child;

          if (snapshot.connectionState == ConnectionState.waiting) {
            child = const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          } else if (snapshot.hasError) {
            child = _buildErrorState(snapshot.error);
          } else if (!snapshot.hasData) {
            child = _buildErrorState('Order details not found');
          } else {
            final orderDetail = snapshot.data!;
            _currentUuid = orderDetail.uuid.isNotEmpty
                ? orderDetail.uuid
                : widget.orderUuid;
            final statusKey = orderDetail.effectiveStatus;
            final isEditable = _canEditOrder(statusKey);

            child = RefreshIndicator(
              color: _primary,
              onRefresh: () async {
                _loadOrderDetail();
                await _orderDetailFuture;
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _buildCustomerDeliveryCard(orderDetail),
                  const SizedBox(height: 16),
                  _buildOrderOverviewCard(orderDetail, _currentUuid),
                  const SizedBox(height: 16),
                  _buildItemsSection(orderDetail, isEditable),
                ],
              ),
            );
          }

          return Stack(
            children: [
              Positioned.fill(child: child),
              if (_isLoading) Positioned.fill(child: _buildLoadingOverlay()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: _softRed,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 40,
                  color: _primary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Failed to load order details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                style: TextStyle(
                  fontSize: 13,
                  color: _muted.withValues(alpha: 0.92),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _loadOrderDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.28),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          decoration: BoxDecoration(
            color: _ink.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 14),
              Text(
                'Please wait...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderOverviewCard(OrderDetail orderDetail, String paymentUuid) {
    final statusKey = orderDetail.effectiveStatus;
    final statusColor = _getStatusColor(statusKey);
    final showPaymentButton = _showPaymentButton(statusKey);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ID',
                          style: TextStyle(
                            fontSize: 12,
                            color: _muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          orderDetail.code,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                    _buildStatusBadge(statusKey, statusColor),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildInfoItem(
                      Icons.storefront_rounded,
                      orderDetail.shopName.isEmpty
                          ? 'N/A'
                          : orderDetail.shopName,
                    ),
                    const SizedBox(width: 12),
                    _buildInfoItem(
                      Icons.calendar_today_rounded,
                      orderDetail.date.isNotEmpty
                          ? orderDetail.date
                          : orderDetail.createdAt,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAmountRow('Subtotal', '€${orderDetail.subtotal}'),
                _buildAmountRow(
                  'Shipping',
                  orderDetail.isDeliveryChargeFree
                      ? 'Free'
                      : '€${orderDetail.shippingCharge}',
                  valueColor: orderDetail.isDeliveryChargeFree
                      ? _success
                      : null,
                ),
                if (_hasMeaningfulAmount(orderDetail.discountAmount))
                  _buildAmountRow(
                    'Discount',
                    '-€${orderDetail.discountAmount}',
                    valueColor: _success,
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Total Payable',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '€${orderDetail.total}',
                        maxLines: 1,
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showPaymentButton)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                width: double.infinity,
                height: 32,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: _primaryGrad),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ElevatedButton(
                  onPressed: paymentUuid.isEmpty
                      ? null
                      : () => _loadPaymentUrl(paymentUuid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'PAY NOW',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        _getStatusLabel(status).toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 14, color: _muted),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: _muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerDeliveryCard(OrderDetail orderDetail) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(28),
            onTap: () {
              setState(() {
                _isCustomerExpanded = !_isCustomerExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: _primaryGrad,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer & Delivery',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${orderDetail.name} • ${orderDetail.mobile}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: _muted,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (orderDetail.city.isNotEmpty)
                              _buildMiniPill(
                                icon: Icons.location_on_outlined,
                                label: orderDetail.city,
                                background: _softAmber,
                                foreground: _primaryDark,
                              ),
                            if (orderDetail.deliveryType.isNotEmpty)
                              _buildMiniPill(
                                icon: Icons.local_shipping_outlined,
                                label: orderDetail.deliveryType,
                                background: _softGreen,
                                foreground: _accent,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _pageBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AnimatedRotation(
                      turns: _isCustomerExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 26,
                        color: _muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(28),
            ),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _isCustomerExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Divider(height: 1, color: _line),
                    const SizedBox(height: 16),
                    _buildInfoRow(
                      icon: Icons.person_rounded,
                      label: 'Customer',
                      value: orderDetail.name,
                    ),
                    _buildInfoRow(
                      icon: Icons.phone_rounded,
                      label: 'Mobile',
                      value: orderDetail.mobile,
                    ),
                    if (orderDetail.email.isNotEmpty)
                      _buildInfoRow(
                        icon: Icons.mail_outline_rounded,
                        label: 'Email',
                        value: orderDetail.email,
                      ),
                    _buildInfoRow(
                      icon: Icons.calendar_today_outlined,
                      label: 'Order Date',
                      value: orderDetail.date.isNotEmpty
                          ? orderDetail.date
                          : orderDetail.createdAt,
                    ),
                    _buildInfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Delivery Address',
                      value: orderDetail.address,
                    ),
                    _buildInfoRow(
                      icon: Icons.map_outlined,
                      label: 'City',
                      value: [
                        orderDetail.city,
                        if (orderDetail.postCode.isNotEmpty)
                          orderDetail.postCode,
                      ].join(', '),
                    ),
                    if (orderDetail.orderRegion.isNotEmpty)
                      _buildInfoRow(
                        icon: Icons.explore_outlined,
                        label: 'Region',
                        value: orderDetail.orderRegion,
                      ),
                    if (orderDetail.deliveryType.isNotEmpty)
                      _buildInfoRow(
                        icon: Icons.flash_on_rounded,
                        label: 'Delivery Type',
                        value: orderDetail.deliveryType,
                      ),
                    if (orderDetail.orderNote.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _softAmber,
                              _softAmber.withValues(alpha: 0.65),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _primary.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Note',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              orderDetail.orderNote,
                              style: const TextStyle(
                                fontSize: 14,
                                color: _ink,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(OrderDetail orderDetail, bool isEditable) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12, right: 4),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Items',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Requested products, stock updates and replacements',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _softAmber,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${orderDetail.orderItems.length} items',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _primaryDark,
                  ),
                ),
              ),
              if (isEditable) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _softGreen,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Editable',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (orderDetail.orderItems.isEmpty)
          _buildSectionCard(
            title: 'No items found',
            icon: Icons.shopping_bag_outlined,
            child: const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'This order does not have any items right now.',
                style: TextStyle(fontSize: 14, color: _muted),
              ),
            ),
          )
        else
          ...orderDetail.orderItems.asMap().entries.map((entry) {
            return _buildOrderItem(
              entry.value,
              entry.key,
              orderDetail,
              isEditable,
            );
          }),
      ],
    );
  }

  Widget _buildOrderItem(
    OrderItem item,
    int index,
    OrderDetail orderDetail,
    bool isEditable,
  ) {
    final imageUrl = _buildProductImageUrl(item.product.image);
    final isUnavailable = !item.isAvailable;
    final hasReplacement = item.replacement != null;
    final canEditThisItem = isEditable && !isUnavailable && !hasReplacement;
    final unitText = item.product.unit.isNotEmpty
        ? item.product.unit
        : item.product.productDetail.displayUnit;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isUnavailable ? _softRed : _itemBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnavailable ? _danger.withValues(alpha: 0.2) : _itemBorder,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProductImage(
                        imageUrl,
                        size: 70,
                        radius: 12,
                        background: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _ink,
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _surface.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: _itemBorder.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Text(
                                unitText,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF3B6B93),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Price and Quantity Row - Responsive Implementation
                            Row(
                              children: [
                                // Price Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _priceBlue,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '€${item.salePrice}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Actions Section
                                Expanded(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (canEditThisItem) ...[
                                        Flexible(
                                          child: _buildQuantityControls(
                                            item,
                                            index,
                                            orderDetail,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        _buildDeleteButton(
                                          item,
                                          index,
                                          orderDetail,
                                        ),
                                      ] else ...[
                                        Text(
                                          '× ${item.quantity}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: _ink,
                                          ),
                                        ),
                                        const Spacer(),
                                        // if (!isEditable &&
                                        //     !isUnavailable &&
                                        //     !hasReplacement),
                                        //   // _buildBuyAgainButton(
                                        //   //   onTap: () =>
                                        //   //       _addOrderItemToCart(item),
                                        //   ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUnavailable)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.replacement == null) ...[
                          GestureDetector(
                            onTap: () => _showInfoDialog(
                              'Out of Stock',
                              'We are extremely sorry! This product is currently unavailable in our stock. Our team will contact you soon regarding this.',
                              Icons.error_outline_rounded,
                              _danger,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.info_outline_rounded,
                                size: 14,
                                color: _danger,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _danger,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (item.replacement != null)
              _buildReplacementCard(
                item,
                item.replacement!,
                index: index,
                orderDetail: orderDetail,
                isEditable: isEditable,
                showAddToCart: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplacementSection(
    OrderReplacement replacement,
    String originalName,
  ) {
    final imageUrl = _buildProductImageUrl(replacement.product.image);
    final unitText = replacement.product.unit.isNotEmpty
        ? replacement.product.unit
        : replacement.product.productDetail.displayUnit;
    final lineTotal =
        (replacement.quantity * (double.tryParse(replacement.salePrice) ?? 0))
            .toStringAsFixed(2);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFE0F7FA),
        border: Border(top: BorderSide(color: Color(0xFF4DD0E1))),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
            color: const Color(0xFF00ACC1),
            child: Row(
              children: [
                const Icon(Icons.swap_horiz, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                const Text(
                  'REPLACEMENT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _showInfoDialog(
                    'Replacement Product',
                    'As your ordered item was out of stock, we have provided this as a suitable replacement to ensure your order is fulfilled.',
                    Icons.published_with_changes_rounded,
                    const Color(0xFF00ACC1),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.yellow,
                    size: 13,
                  ),
                ),
                const Spacer(),
                Text(
                  'For $originalName',
                  style: const TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _buildProductImage(
                  imageUrl,
                  size: 50,
                  radius: 8,
                  background: Colors.white,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        replacement.product.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF006064),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: const Color(0xFFB2EBF2),
                              ),
                            ),
                            child: Text(
                              unitText,
                              style: const TextStyle(
                                fontSize: 9,
                                color: Color(0xFF00838F),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00BCD4),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '€${replacement.salePrice}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '× ${replacement.quantity}  =  €$lineTotal',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF00838F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplacementCard(
    OrderItem item,
    OrderReplacement replacement, {
    required int index,
    required OrderDetail orderDetail,
    required bool isEditable,
    bool showAddToCart = false,
  }) {
    final imageUrl = _buildProductImageUrl(replacement.product.image);
    final canEditReplacement = isEditable;
    final lineTotal =
        (item.quantity * (double.tryParse(replacement.salePrice) ?? 0))
            .toStringAsFixed(2);
    final replacementUnit = replacement.product.unit.isNotEmpty
        ? replacement.product.unit
        : replacement.product.productDetail.displayUnit;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF6FFFE), Color(0xFFE6F6F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent.withValues(alpha: 0.24), width: 1.3),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -26,
            right: -8,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1EB7A8).withValues(alpha: 0.18),
                    const Color(0xFF1EB7A8).withValues(alpha: 0.01),
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: _accentGrad,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.20),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'REPLACEMENT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.9,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'For ${item.product.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.94),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductImage(
                          imageUrl,
                          size: 72,
                          radius: 20,
                          background: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                replacement.product.name,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0D4E48),
                                  height: 1.35,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 9),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildItemTag(
                                    text: replacementUnit,
                                    background: Colors.white,
                                    textColor: const Color(0xFF0D4E48),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: _accentGrad,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _accent.withValues(
                                            alpha: 0.16,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      '€${replacement.salePrice}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  if (canEditReplacement) ...[
                                    _buildQuantityControls(
                                      item,
                                      index,
                                      orderDetail,
                                    ),
                                    _buildDeleteButton(
                                      item,
                                      index,
                                      orderDetail,
                                    ),
                                  ] else
                                    _buildItemTag(
                                      text: 'Qty ${item.quantity}',
                                      background: const Color(0xFFD8F0EC),
                                      textColor: const Color(0xFF00695C),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDFF3EF).withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _accent.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.88),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Color(0xFF00897B),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: const Text(
                              'Replacement item selected',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2D6B64),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.96),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: _accent.withValues(alpha: 0.12),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4E7E78),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '€$lineTotal',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF004D40),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductImage(
    String imageUrl, {
    double size = 88,
    double radius = 20,
    Color background = const Color(0xFFFFFBF6),
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.80)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: imageUrl.isEmpty
            ? Icon(
                Icons.shopping_bag_outlined,
                color: _muted.withValues(alpha: 0.70),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.broken_image_outlined,
                  color: _muted.withValues(alpha: 0.70),
                ),
              ),
      ),
    );
  }

  Future<void> _addOrderItemToCart(OrderItem item) async {
    await _addProductToCart(
      productId: item.productId,
      name: item.product.name,
      image: item.product.image,
      price: double.tryParse(item.salePrice) ?? 0.0,
      originalPrice: double.tryParse(item.product.salePrice) ?? 0.0,
      salesPriceWithCharge:
          double.tryParse(item.product.salesPriceWithCharge) ?? 0.0,
      weight: item.weight,
      unit: item.product.unit,
    );
  }

  Future<void> _addReplacementToCart(
    OrderReplacement replacement, {
    String fallbackWeight = '',
  }) async {
    await _addProductToCart(
      productId: replacement.product.id,
      name: replacement.product.name,
      image: replacement.product.image,
      price: double.tryParse(replacement.salePrice) ?? 0.0,
      originalPrice: double.tryParse(replacement.product.salePrice) ?? 0.0,
      salesPriceWithCharge:
          double.tryParse(replacement.product.salesPriceWithCharge) ?? 0.0,
      weight: replacement.product.weight.isNotEmpty
          ? replacement.product.weight
          : fallbackWeight,
      unit: replacement.product.unit,
    );
  }

  Future<void> _addProductToCart({
    required int productId,
    required String name,
    required String image,
    required double price,
    required double originalPrice,
    required double salesPriceWithCharge,
    required String weight,
    required String unit,
  }) async {
    final cartManager = Provider.of<CartManager>(context, listen: false);

    final cartItem = CartItem(
      id: productId,
      name: name,
      image: image,
      price: price,
      originalPrice: originalPrice,
      salesPriceWithCharge: salesPriceWithCharge,
      weight: weight,
      unit: unit,
      sellerId: 0,
      sellerName: '',
      quantity: 1,
    );

    final success = await cartManager.addItem(cartItem);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name added to cart'),
          backgroundColor: _success,
          duration: const Duration(seconds: 1),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please login to add items to cart'),
          backgroundColor: _danger,
        ),
      );
    }
  }

  void _showInfoDialog(
    String title,
    String message,
    IconData icon,
    Color color,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: _ink,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Understood',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(
    OrderItem item,
    int index,
    OrderDetail orderDetail,
  ) {
    return InkWell(
      onTap: () => _showDeleteDialog(item, index, orderDetail),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _softRed,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _danger.withValues(alpha: 0.12)),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: _danger,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildQuantityControls(
    OrderItem item,
    int index,
    OrderDetail orderDetail,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onTap: () {
              if (item.quantity > 1) {
                _updateQuantity(item, item.quantity - 1, index, orderDetail);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Minimum quantity is 1'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          SizedBox(
            width: 30,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onTap: () =>
                _updateQuantity(item, item.quantity + 1, index, orderDetail),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: _primary),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _softAmber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _primary),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _pageBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: _muted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value.isEmpty ? '-' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    String value, {
    Color? valueColor,
    bool isEmphasized = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isEmphasized ? 15 : 14,
                fontWeight: isEmphasized ? FontWeight.w700 : FontWeight.w500,
                color: _muted,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isEmphasized ? 20 : 15,
              fontWeight: FontWeight.w800,
              color: valueColor ?? _ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBadge({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3E4F4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF4B7CA5)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF466987),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHighlight({
    required String label,
    required String value,
    bool dark = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: dark
            ? LinearGradient(
                colors: [const Color(0xFFFFFFFF), const Color(0xFFF1F8FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: dark ? null : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? const Color(0xFFD8E8F7) : _line.withValues(alpha: 0.80),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: dark ? const Color(0xFF6C8AA3) : _muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: dark ? const Color(0xFF1F4462) : _ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF3E698A),
        side: const BorderSide(color: Color(0xFFD5E6F5)),
        backgroundColor: Colors.white.withValues(alpha: 0.94),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildItemTag({
    required String text,
    required Color background,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildMiniPill({
    required IconData icon,
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) {
    switch (_normalizeStatus(status)) {
      case 'accept_payment_pending':
      case 'hold':
      case 'accept_failed':
        return Icons.pending_actions_rounded;
      case 'accept_paid':
      case 'approved':
        return Icons.verified_rounded;
      case 'pickup':
        return Icons.inventory_2_rounded;
      case 'transit':
        return Icons.local_shipping_rounded;
      case 'delivered':
        return Icons.task_alt_rounded;
      case 'delivery_failed':
      case 'returned':
      case 'cancelled':
        return Icons.cancel_rounded;
      case 'processing':
        return Icons.autorenew_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  Color _getStatusColor(String status) {
    switch (_normalizeStatus(status)) {
      case 'accept_payment_pending':
      case 'hold':
      case 'accept_failed':
        return const Color(0xFFD84315);
      case 'accept_paid':
        return const Color(0xFF2E7D32);
      case 'approved':
        return const Color(0xFFEF6C00);
      case 'pickup':
        return const Color(0xFF00897B);
      case 'transit':
        return const Color(0xFF1565C0);
      case 'delivered':
        return const Color(0xFF2E7D32);
      case 'delivery_failed':
      case 'returned':
        return const Color(0xFFC62828);
      case 'cancelled':
        return const Color(0xFF757575);
      case 'processing':
        return const Color(0xFF5E35B1);
      default:
        return _primary;
    }
  }

  String _getStatusLabel(String status) {
    switch (_normalizeStatus(status)) {
      case 'accept_payment_pending':
        return 'Accept (Payment Pending)';
      case 'hold':
        return 'On Hold';
      case 'accept_failed':
        return 'Payment Failed';
      case 'accept_paid':
        return 'Payment Completed';
      case 'approved':
        return 'Approved';
      case 'pickup':
        return 'Ready for Pickup';
      case 'transit':
        return 'Parcel on the Way';
      case 'delivered':
        return 'Delivered Successfully';
      case 'delivery_failed':
        return 'Delivery Failed';
      case 'returned':
        return 'Returned';
      case 'cancelled':
        return 'Cancelled';
      case 'processing':
        return 'Processing';
      default:
        return status;
    }
  }

  bool _hasMeaningfulAmount(String amount) {
    final value = double.tryParse(amount) ?? 0;
    return value > 0;
  }

  String _buildProductImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    final normalizedPath = imagePath.replaceAll('\\', '/');
    return ApiConstants.getImageUrl('product/$normalizedPath');
  }

  Future<void> _updateQuantity(
    OrderItem item,
    int newQty,
    int index,
    OrderDetail orderDetail,
  ) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final result = await _orderService.updateOrderItem(
        widget.orderId,
        item.id,
        newQty,
        userProvider.token ?? '',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      orderDetail.orderItems[index].quantity = newQty;

      if (result['newTotal'] != null) {
        orderDetail.total = result['newTotal'];
      }

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quantity updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(OrderItem item, int index, OrderDetail orderDetail) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Item'),
          content: const Text(
            'Are you sure you want to remove this item from the order?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _deleteItem(item, index, orderDetail);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes, Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(
    OrderItem item,
    int index,
    OrderDetail orderDetail,
  ) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final result = await _orderService.deleteOrderItem(
        widget.orderId,
        item.id,
        userProvider.token ?? '',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      orderDetail.orderItems.removeAt(index);

      if (result['newTotal'] != null) {
        orderDetail.total = result['newTotal'];
      }

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item removed successfully'),
          backgroundColor: Colors.green,
        ),
      );

      if (orderDetail.orderItems.isEmpty) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove item: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
