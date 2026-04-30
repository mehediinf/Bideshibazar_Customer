// lib/presentation/checkout/checkout_view.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/cart_manager.dart';
import '../../core/utils/app_error_helper.dart';
import '../address/manage_address_view.dart';
import '../order_success/order_success_view.dart';
import 'checkout_viewmodel.dart';
import '../../core/network/api_constants.dart';

class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  late CheckoutViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = CheckoutViewModel();
    _viewModel.initialize();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkMultipleStores();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _checkMultipleStores() {
    final cartManager = context.read<CartManager>();
    final sellerIds = cartManager.items.map((item) => item.sellerId).toSet();

    if (sellerIds.length > 1) {
      _showMultipleStoresDialog();
    }
  }

  void _showMultipleStoresDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8F0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(Icons.store, size: 32, color: Colors.orange.shade600),
                    Positioned(
                      right: 12,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Multiple Stores Detected',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You are purchasing from multiple stores.\nDelivery charges may vary.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
      ),
    );
  }

  Future<void> _handleVerify() async {
    if (!_formKey.currentState!.validate()) return;

    if (_viewModel.addressController.text.isEmpty) {
      _showSnackBar('Please select a delivery address', Colors.red.shade700);
      return;
    }

    final cartManager = context.read<CartManager>();
    final subtotal = cartManager.totalPrice;

    if (subtotal < 50.0) {
      _showSnackBar(
        'Minimum order amount is €50.00. Current: €${subtotal.toStringAsFixed(2)}',
        Colors.orange.shade700,
      );
      return;
    }

    final error = await _viewModel.verifyAddress(subtotal);

    if (error != null) {
      _showSnackBar(error, Colors.red.shade700);
    } else {
      final message = _viewModel.verifyResponse?.message ?? 'Address verified successfully!';
      _showSnackBar(message, Colors.green.shade700);
    }
  }

  Future<void> _handlePlaceOrder() async {
    final cartManager = context.read<CartManager>();
    final result = await _viewModel.placeOrder(cartManager);

    if (result == null) {
      _showSnackBar(
        AppErrorHelper.toUserMessage(
          null,
          fallback: 'Something went wrong while placing the order.',
        ),
        Colors.red.shade700,
      );
      return;
    }

    if (result.containsKey('error')) {
      _showSnackBar(
        AppErrorHelper.toUserMessage(result['error']),
        Colors.red.shade700,
      );
    } else if (result['success'] == true) {
      final orderNumber = result['order_number'] ?? 'ORD00089';
      final userName = result['user_name'] ?? 'Customer';

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OrderSuccessView(
              orderNumber: orderNumber,
              userName: userName,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: _buildAppBar(),
        body: Consumer2<CheckoutViewModel, CartManager>(
          builder: (context, viewModel, cartManager, _) {
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: _buildMainContent(viewModel, cartManager),
                  ),
                ),
                _buildBottomBar(viewModel, cartManager),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Checkout',
        style: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Colors.white,
          letterSpacing: 0.3,
        ),
      ),
      centerTitle: true,
      backgroundColor: const Color(0xFF0095FF),
      foregroundColor: Colors.white,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildMainContent(CheckoutViewModel viewModel, CartManager cartManager) {
    final subtotal = cartManager.totalPrice;
    final deliveryFee = viewModel.verifyResponse?.deliveryCharge ?? 0.0;
    final total = subtotal + deliveryFee;
    final isMinimumOrderMet = subtotal >= 50.0;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Minimum Order Warning
            if (!isMinimumOrderMet)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Minimum Order: €50.00',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Add €${(50.0 - subtotal).toStringAsFixed(2)} more',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            _buildSectionCard(
              title: 'Contact Info',
              icon: Icons.person_outline,
              child: Column(
                children: [
                  _buildTextField(
                    controller: viewModel.nameController,
                    hint: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: viewModel.emailController,
                    hint: 'Email Address',
                    icon: Icons.email_outlined,
                    enabled: !viewModel.isEmailLogin,
                    validator: (val) {
                      if (val!.isEmpty) return 'Required';
                      if (!val.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildMobileField(viewModel),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Delivery Address',
              icon: Icons.location_on_outlined,
              child: Column(
                children: [
                  _buildAddressField(viewModel),
                  const SizedBox(height: 10),
                  _buildTextField(
                    controller: viewModel.roomController,
                    hint: 'Tur/Room No. (Optional)',
                    icon: Icons.door_front_door_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Delivery Options',
              icon: Icons.local_shipping_outlined,
              child: Column(
                children: [
                  _buildDeliveryType(viewModel),
                  if (viewModel.deliveryType == 'scheduled') ...[
                    const SizedBox(height: 10),
                    _buildScheduledTimeDropdown(viewModel),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Order Notes (Optional)',
              icon: Icons.note_outlined,
              child: _buildTextField(
                controller: viewModel.orderNotesController,
                hint: 'Special instructions...',
                icon: Icons.edit_outlined,
                maxLines: 3,
              ),
            ),
            const SizedBox(height: 16),
            _buildVerifyButton(viewModel, isMinimumOrderMet),
            if (viewModel.isVerified && viewModel.verifyResponse != null) ...[
              const SizedBox(height: 16),
              _buildDeliveryPartnerCard(viewModel),
              const SizedBox(height: 16),
              _buildOrderSummaryCard(cartManager),
              const SizedBox(height: 16),
              _buildPriceSummaryCard(subtotal, deliveryFee, total),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0095FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: const Color(0xFF0095FF), size: 16),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 18),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF0095FF), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade300),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      ),
    );
  }

  Widget _buildMobileField(CheckoutViewModel viewModel) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 16,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: Colors.grey.shade300),
                  image: const DecorationImage(
                    image: NetworkImage('https://flagcdn.com/w40/at.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                viewModel.countryCode,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            controller: viewModel.mobileController,
            keyboardType: TextInputType.phone,
            enabled: viewModel.isEmailLogin,
            validator: (val) => val!.isEmpty ? 'Required' : null,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Mobile Number',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey.shade400, size: 18),
              filled: true,
              fillColor: viewModel.isEmailLogin ? Colors.grey.shade50 : Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF0095FF), width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressField(CheckoutViewModel viewModel) {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const ManageAddressView(isFromCheckout: true),
          ),
        );

        if (result != null && result is Map<String, dynamic>) {
          viewModel.updateAddress(result);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(
            color: viewModel.addressController.text.isEmpty
                ? Colors.red.shade300
                : Colors.grey.shade200,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: viewModel.addressController.text.isEmpty
                  ? Colors.red.shade400
                  : const Color(0xFF0095FF),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                viewModel.addressController.text.isEmpty
                    ? 'Select delivery address *'
                    : viewModel.addressController.text,
                style: TextStyle(
                  color: viewModel.addressController.text.isEmpty
                      ? Colors.red.shade400
                      : const Color(0xFF1A1A1A),
                  fontSize: 13,
                  fontWeight: viewModel.addressController.text.isEmpty
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryType(CheckoutViewModel viewModel) {
    return Row(
      children: [
        Expanded(
          child: _buildDeliveryOption(
            title: 'Express',
            subtitle: 'ASAP',
            icon: Icons.electric_bolt,
            isSelected: viewModel.deliveryType == 'express',
            onTap: () => viewModel.setDeliveryType('express'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildDeliveryOption(
            title: 'Scheduled',
            subtitle: 'Choose time',
            icon: Icons.schedule,
            isSelected: viewModel.deliveryType == 'scheduled',
            onTap: () => viewModel.setDeliveryType('scheduled'),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0095FF).withOpacity(0.1) : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? const Color(0xFF0095FF) : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF0095FF) : Colors.grey.shade600,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? const Color(0xFF0095FF) : const Color(0xFF1A1A1A),
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledTimeDropdown(CheckoutViewModel viewModel) {
    final timeSlots = viewModel.generateTimeSlots();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: viewModel.scheduledTime,
          hint: Text(
            'Select delivery time',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600, size: 20),
          items: timeSlots.map((time) {
            return DropdownMenuItem(
              value: time,
              child: Text(time, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (val) => viewModel.setScheduledTime(val),
        ),
      ),
    );
  }

  Widget _buildVerifyButton(CheckoutViewModel viewModel, bool isMinimumOrderMet) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: (viewModel.isVerifying || !isMinimumOrderMet) ? null : _handleVerify,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFC107),
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: viewModel.isVerifying
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              viewModel.isVerified ? Icons.check_circle : Icons.verified_outlined,
              size: 18,
              color: isMinimumOrderMet ? Colors.black87 : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              viewModel.isVerified ? 'VERIFIED ✓' : 'VERIFY ADDRESS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isMinimumOrderMet ? Colors.black87 : Colors.grey.shade600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryPartnerCard(CheckoutViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0095FF).withOpacity(0.08),
            const Color(0xFF00CCBC).withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF0095FF).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Image.network(
              viewModel.verifyResponse!.deliveryPartnerLogo,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.delivery_dining,
                color: Color(0xFF0095FF),
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.verifyResponse!.deliveryPartner,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      viewModel.verifyResponse!.approxDeliveryTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 24),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryCard(CartManager cartManager) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0095FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFF0095FF),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: cartManager.items.map((item) {
                String productImage;
                if (item.image.startsWith('http://') || item.image.startsWith('https://')) {
                  productImage = item.image;
                } else if (item.image.startsWith('uploads/')) {
                  productImage = ApiConstants.baseUrlWithoutApi + '${item.image}';
                } else {
                  productImage = '${ApiConstants.baseUrlWithoutApi}/uploads/product/${item.image}';
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade100,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(
                          productImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.image_outlined,
                            color: Colors.grey.shade400,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '€${item.displayPrice.toStringAsFixed(2)} • ${item.weight} ${item.unit}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0095FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'x${item.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0095FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummaryCard(double subtotal, double deliveryFee, double total) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              Text(
                '€${subtotal.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text('Delivery Fee', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                ],
              ),
              Text(
                deliveryFee == 0 || deliveryFee == 0.0 ? 'FREE' : '€${deliveryFee.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: deliveryFee == 0 || deliveryFee == 0.0
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                '€${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0095FF),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(CheckoutViewModel viewModel, CartManager cartManager) {
    final subtotal = cartManager.totalPrice;
    final deliveryFee = viewModel.verifyResponse?.deliveryCharge ?? 0.0;
    final total = subtotal + deliveryFee;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (viewModel.isVerified && !viewModel.isPlacingOrder) ? _handlePlaceOrder : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0095FF),
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: viewModel.isPlacingOrder
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag, size: 18),
                  const SizedBox(width: 10),
                  const Text(
                    'Place Order',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '€${total.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
