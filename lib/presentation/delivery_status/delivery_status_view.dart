// lib/presentation/delivery_status/delivery_status_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/providers/user_provider.dart';
import '../../core/services/order_service.dart';
import '../../core/utils/app_error_helper.dart';
import '../../data/models/delivery_status_model.dart';

class DeliveryStatusView extends StatefulWidget {
  final int orderId;

  const DeliveryStatusView({
    super.key,
    required this.orderId,
  });

  @override
  State<DeliveryStatusView> createState() => _DeliveryStatusViewState();
}

class _DeliveryStatusViewState extends State<DeliveryStatusView> {
  final OrderService _orderService = OrderService();
  late Future<DeliveryStatusModel> _deliveryFuture;
  WebViewController? _webViewController;

  @override
  void initState() {
    super.initState();
    _loadDeliveryDetails();
  }

  void _loadDeliveryDetails() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() {
      _deliveryFuture = _orderService.getDeliveryDetails(
        widget.orderId,
        userProvider.token ?? '',
      );
    });
  }

  void _copyToClipboard(String text) {
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied: $text'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nothing to copy!'),
          duration: Duration(seconds: 1),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Toolbar
            _buildToolbar(),

            // Divider
            const Divider(height: 1, thickness: 1, color: Color(0xFFDDDDDD)),

            // Main Content
            Expanded(
              child: FutureBuilder<DeliveryStatusModel>(
                future: _deliveryFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (snapshot.hasError) {
                    return _buildErrorView(
                      AppErrorHelper.toUserMessage(snapshot.error),
                    );
                  }

                  final delivery = snapshot.data!.deliveryDetails;

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Consignment ID Section
                        _buildConsignmentSection(delivery.woltOrderId),

                        Container(
                          height: 5,
                          color: const Color(0xFFE0E0E0),
                        ),

                        // Shipping Info Section
                        _buildShippingInfoSection(delivery),

                        Container(
                          height: 10,
                          color: const Color(0xFFE0E0E0),
                        ),

                        // Expected Delivery Section
                        _buildExpectedDeliverySection(delivery.approxDeliveryTime),

                        Container(
                          height: 5,
                          color: const Color(0xFFE0E0E0),
                        ),

                        // Timeline Section
                        _buildTimelineSection(delivery.status),

                        Container(
                          height: 10,
                          color: const Color(0xFFE0E0E0),
                        ),

                        // Delivery Type & Partner Section
                        _buildDeliveryPartnerSection(delivery),

                        // Tracking WebView (if available)
                        if (delivery.trackingUrl.isNotEmpty)
                          _buildTrackingWebView(delivery.trackingUrl),

                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 34,
              height: 34,
              padding: const EdgeInsets.all(5),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.black,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Delivery Details',
            style: TextStyle(
              color: Color(0xFF1D1A1A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 80,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load delivery details',
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
              error,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadDeliveryDetails,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildConsignmentSection(String consignmentId) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Consignment ID',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                consignmentId,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _copyToClipboard(consignmentId),
                child: const Icon(
                  Icons.copy,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfoSection(DeliveryDetails delivery) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          const Text(
            'Shipping Info',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            delivery.mobile,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            delivery.name,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            delivery.email,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF444444),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            delivery.address,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF444444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpectedDeliverySection(String expectedDate) {
    final displayDate = expectedDate == 'null' || expectedDate == 'N/A'
        ? 'Not Available'
        : expectedDate;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 18),
          const Text(
            'Expected Delivery',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            displayDate,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFd9534f),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(String status) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Timeline',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1A1A),
            ),
          ),
          const SizedBox(height: 16),
          _buildTimeline(status.toLowerCase()),
        ],
      ),
    );
  }

  Widget _buildTimeline(String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildTimelineStep('Confirm', 0, status)),
          Expanded(child: _buildTimelineStep('Picked-up', 1, status)),
          Expanded(child: _buildTimelineStep('In Transit', 2, status)),
          Expanded(child: _buildTimelineStep('Delivered', 3, status)),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String label, int stepIndex, String status) {
    // Determine status based on step and current status
    bool isCompleted = false;
    bool isRunning = false;
    bool isFailed = false;

    switch (status) {
      case 'approved':
        isRunning = stepIndex == 0;
        isCompleted = false;
        break;
      case 'pickup':
        isCompleted = stepIndex == 0;
        isRunning = stepIndex == 1;
        break;
      case 'transit':
        isCompleted = stepIndex <= 1;
        isRunning = stepIndex == 2;
        break;
      case 'delivered':
        isCompleted = true;
        break;
      case 'delivery_failed':
      case 'returned':
        isCompleted = stepIndex <= 1;
        isFailed = stepIndex >= 2;
        break;
      default:
        break;
    }

    // Circle color and icon based on status
    Color circleColor;
    IconData? icon;

    if (isFailed) {
      circleColor = Colors.red;
      icon = Icons.close;
    } else if (isCompleted) {
      circleColor = const Color(0xFF4CAF50);
      icon = Icons.check;
    } else if (isRunning) {
      circleColor = const Color(0xFF4CAF50);
      icon = Icons.fiber_manual_record;
    } else {
      circleColor = Colors.grey[300]!;
      icon = null;
    }

    // Line colors
    Color leftLineColor = (stepIndex > 0 && (isCompleted || (isRunning && stepIndex > 0)))
        ? const Color(0xFF4CAF50)
        : Colors.grey[300]!;

    return Column(
      children: [
        // Image at the top
        Image.asset(
          _getStepImagePath(stepIndex),
          width: 56,
          height: 56,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Image load failed: ${_getStepImagePath(stepIndex)}');
            print('Error: $error');
            return _buildFallbackIcon(stepIndex);
          },
        ),

        const SizedBox(height: 8),

        // Line and Circle Row
        SizedBox(
          height: 22,
          child: Row(
            children: [
              // Left line
              if (stepIndex > 0)
                Expanded(
                  child: CustomPaint(
                    painter: DashedLinePainter(
                      color: leftLineColor,
                      dashWidth: 4,
                      dashSpace: 4,
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox()),

              // Circle
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: circleColor,
                  shape: BoxShape.circle,
                ),
                child: icon != null
                    ? Icon(icon, size: 14, color: Colors.white)
                    : null,
              ),

              // Right line
              if (stepIndex < 3)
                Expanded(
                  child: CustomPaint(
                    painter: DashedLinePainter(
                      color: Colors.grey[300]!,
                      dashWidth: 4,
                      dashSpace: 4,
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Label
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }

  // Fallback icon if image doesn't load
  Widget _buildFallbackIcon(int stepIndex) {
    IconData iconData;
    Color bgColor;

    switch (stepIndex) {
      case 0:
        iconData = Icons.inventory_2;
        bgColor = Colors.orange[100]!;
        break;
      case 1:
        iconData = Icons.local_shipping;
        bgColor = Colors.red[100]!;
        break;
      case 2:
        iconData = Icons.airport_shuttle;
        bgColor = Colors.green[100]!;
        break;
      case 3:
        iconData = Icons.home;
        bgColor = Colors.pink[100]!;
        break;
      default:
        iconData = Icons.circle;
        bgColor = Colors.grey[200]!;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: Colors.grey[700],
        size: 28,
      ),
    );
  }

  String _getStepImagePath(int stepIndex) {
    switch (stepIndex) {
      case 0:
        return 'assets/images/ic_confirm_active.png';
      case 1:
        return 'assets/images/ic_picked_active.png';
      case 2:
        return 'assets/images/ic_transit_active.png';
      case 3:
        return 'assets/images/ic_delivered_inactive.png';
      default:
        return 'assets/images/ic_confirm_active.png';
    }
  }

  Widget _buildDeliveryPartnerSection(DeliveryDetails delivery) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Delivery Type
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Delivery Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  delivery.deliveryType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),

          const Divider(height: 24, thickness: 1, color: Color(0xFFDDDDDD)),

          // Delivery Partner
          const Text(
            'Delivery Partner',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              // Partner Logo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[200],
                ),
                child: ClipOval(
                  child: delivery.deliveryPartnerLogo.isNotEmpty
                      ? Image.network(
                    delivery.deliveryPartnerLogo,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.local_shipping,
                        size: 30,
                        color: Colors.grey,
                      );
                    },
                  )
                      : const Icon(
                    Icons.local_shipping,
                    size: 30,
                    color: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Partner Name
              Expanded(
                child: Text(
                  delivery.deliveryPartner,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingWebView(String trackingUrl) {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(trackingUrl));

    return Container(
      height: 500,
      margin: const EdgeInsets.only(top: 16, bottom: 10),
      child: WebViewWidget(controller: _webViewController!),
    );
  }
}

// Custom painter for dashed line
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double dashWidth;
  final double dashSpace;

  DashedLinePainter({
    required this.color,
    this.dashWidth = 4,
    this.dashSpace = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


