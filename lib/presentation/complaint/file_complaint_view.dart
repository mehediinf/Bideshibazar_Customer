

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/network/api_constants.dart';
import '../../core/services/complaint_service.dart';
import '../../core/utils/app_error_helper.dart';
import '../../data/models/complaint_models.dart';

class FileComplaintView extends StatefulWidget {
  const FileComplaintView({super.key});

  @override
  State<FileComplaintView> createState() => _FileComplaintViewState();
}

class _FileComplaintViewState extends State<FileComplaintView> {
  final ComplaintService _complaintService = ComplaintService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _complaintTextController =
      TextEditingController();
  final TextEditingController _detailController = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _showHistory = false;
  int _currentStep = 1;

  List<EligibleComplaintOrder> _orders = const [];
  List<ComplaintLookupItem> _categories = const [];
  List<ComplaintLookupItem> _statuses = const [];
  List<ComplaintHistoryItem> _complaints = const [];

  EligibleComplaintOrder? _selectedOrder;
  ComplaintLookupItem? _selectedCategory;
  File? _selectedPhoto;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _loadComplaintData();
  }

  @override
  void dispose() {
    _complaintTextController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _loadComplaintData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lookups = await _complaintService.getComplaintLookups();
      final orders = await _complaintService.getEligibleOrders();
      final complaints = await _complaintService.getComplaints();

      if (!mounted) return;

      setState(() {
        _categories = lookups.categories;
        _statuses = lookups.statuses;
        _orders = orders;
        _complaints = complaints;
        _selectedOrder = orders.isNotEmpty ? orders.first : null;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = AppErrorHelper.toUserMessage(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _submitComplaint() async {
    if (_selectedOrder == null || _selectedCategory == null) {
      _showSnackBar('Please complete the first two steps.');
      return;
    }

    if (_complaintTextController.text.trim().isEmpty) {
      _showSnackBar('Please describe the issue.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final message = await _complaintService.submitComplaint(
        orderId: _selectedOrder!.id,
        category: _selectedCategory!.key,
        complaintText: _complaintTextController.text.trim(),
        conditionalDetail: _detailController.text.trim(),
        photo: _selectedPhoto,
      );
      final complaints = await _complaintService.getComplaints();

      if (!mounted) return;

      setState(() {
        _successMessage = message;
        _complaints = complaints;
        _isSubmitting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showSnackBar(AppErrorHelper.toUserMessage(error));
    }
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1440,
    );

    if (pickedFile == null || !mounted) return;

    setState(() => _selectedPhoto = File(pickedFile.path));
  }

  void _resetFlow() {
    setState(() {
      _successMessage = null;
      _showHistory = false;
      _currentStep = 1;
      _selectedCategory = null;
      _selectedPhoto = null;
      _selectedOrder = _orders.isNotEmpty ? _orders.first : null;
      _complaintTextController.clear();
      _detailController.clear();
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _statusLabel(String statusKey) {
    for (final status in _statuses) {
      if (status.key.toLowerCase() == statusKey.toLowerCase()) {
        return status.label;
      }
    }
    return statusKey.replaceAll('_', ' ').trim();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return const Color(0xFF38A169);
      case 'in_progress':
        return const Color(0xFFDD6B20);
      default:
        return const Color(0xFFD69E2E);
    }
  }

  IconData _categoryIcon(String key) {
    switch (key) {
      case 'not_received':
        return Icons.inventory_2_outlined;
      case 'wrong_items':
        return Icons.swap_horiz_rounded;
      case 'missing_items':
        return Icons.search_rounded;
      case 'damaged':
        return Icons.heart_broken_outlined;
      case 'late':
        return Icons.schedule_rounded;
      default:
        return Icons.chat_bubble_outline_rounded;
    }
  }

  String _categorySubtitle(String key) {
    switch (key) {
      case 'not_received':
        return 'Marked delivered but never arrived';
      case 'wrong_items':
        return 'You received different products';
      case 'missing_items':
        return 'Some items were missing';
      case 'damaged':
        return 'Items arrived broken or in poor condition';
      case 'late':
        return 'Delivery arrived later than expected';
      default:
        return 'Something else went wrong';
    }
  }

  bool _isCompactWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width < 380;
  }

  @override
  Widget build(BuildContext context) {
    final compactWidth = _isCompactWidth(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'File Complaint',
          style: TextStyle(
            color: Color(0xFF111827),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : RefreshIndicator(
              onRefresh: _loadComplaintData,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  compactWidth ? 12 : 16,
                  12,
                  compactWidth ? 12 : 16,
                  24,
                ),
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 16),
                  _buildTabSwitcher(),
                  const SizedBox(height: 16),
                  if (_successMessage != null)
                    _buildSuccessState()
                  else if (_showHistory)
                    _buildHistoryView()
                  else
                    _buildComplaintForm(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeroCard() {
    final compactWidth = _isCompactWidth(context);

    return Container(
      padding: EdgeInsets.all(compactWidth ? 16 : 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F9D8A), Color(0xFF1CB5A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F9D8A).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Icon(Icons.support_agent_rounded, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'We will help you resolve your order issue quickly.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compactWidth ? 16 : 17,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Choose the order, tell us what happened, and add a photo if it helps. The flow stays simple and mobile-friendly.',
            style: TextStyle(
              color: Colors.white,
              fontSize: compactWidth ? 12.5 : 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    final compactWidth = _isCompactWidth(context);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EEEA)),
      ),
      child: Row(
        children: [
          _buildTabButton(
            label: 'New Complaint',
            icon: Icons.add_circle_outline_rounded,
            selected: !_showHistory,
            onTap: () => setState(() => _showHistory = false),
            compactWidth: compactWidth,
          ),
          const SizedBox(width: 8),
          _buildTabButton(
            label: 'My Complaints',
            icon: Icons.receipt_long_outlined,
            selected: _showHistory,
            onTap: () => setState(() => _showHistory = true),
            compactWidth: compactWidth,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required bool compactWidth,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: EdgeInsets.symmetric(
            horizontal: compactWidth ? 10 : 12,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: selected ? const Color(0xFFE8F8F5) : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected
                    ? const Color(0xFF0F9D8A)
                    : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compactWidth ? 12 : 13,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFF0F9D8A)
                        : const Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintForm() {
    final compactWidth = _isCompactWidth(context);

    return Container(
      padding: EdgeInsets.all(compactWidth ? 14 : 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EFEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepper(),
          const SizedBox(height: 22),
          if (_currentStep == 1) _buildOrderStep(),
          if (_currentStep == 2) _buildCategoryStep(),
          if (_currentStep == 3) _buildDetailsStep(),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: List.generate(3, (index) {
        final step = index + 1;
        final isActive = step <= _currentStep;

        return Expanded(
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFF0F9D8A)
                      : const Color(0xFFE5E7EB),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$step',
                  style: TextStyle(
                    color: isActive ? Colors.white : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (step != 3)
                Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    color: step < _currentStep
                        ? const Color(0xFF0F9D8A)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOrderStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 1 of 3 - Select your order',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Choose a delivered order that needs support.',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        if (_orders.isEmpty)
          _buildSoftEmptyState(
            icon: Icons.inventory_outlined,
            title: 'No eligible orders found',
            subtitle:
                'When a recent order becomes eligible, it will appear here.',
          )
        else
          ..._orders.map(_buildOrderCard),
        const SizedBox(height: 18),
        _buildPrimaryButton(
          label: 'Next',
          icon: Icons.arrow_forward_rounded,
          onTap: _selectedOrder == null
              ? null
              : () => setState(() => _currentStep = 2),
        ),
      ],
    );
  }

  Widget _buildOrderCard(EligibleComplaintOrder order) {
    final selected = _selectedOrder?.id == order.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedOrder = order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF0F9D8A) : const Color(0xFFE5E7EB),
            width: selected ? 1.6 : 1,
          ),
          color: selected ? const Color(0xFFF1FCF9) : const Color(0xFFFBFCFC),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '# ${order.code}',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: selected
                          ? const Color(0xFF0F9D8A)
                          : const Color(0xFF111827),
                    ),
                  ),
                ),
                if (selected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF0F9D8A),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              order.shop,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _buildMetaPill(Icons.calendar_today_outlined, order.date),
                _buildMetaPill(Icons.euro_rounded, '€ ${order.total}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryStep() {
    final compactWidth = _isCompactWidth(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Step 2 of 3 - What went wrong?',
          style: TextStyle(
            fontSize: compactWidth ? 18 : 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pick the option that best describes the issue.',
          style: TextStyle(
            fontSize: compactWidth ? 13 : 14,
            color: const Color(0xFF6B7280),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final crossAxisCount = maxWidth >= 760
                ? 3
                : maxWidth >= 360
                ? 2
                : 1;
            final cardHeight = crossAxisCount == 1
                ? 156.0
                : compactWidth
                ? 190.0
                : 178.0;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                mainAxisExtent: cardHeight,
              ),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = _selectedCategory?.key == category.key;

                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    padding: EdgeInsets.all(compactWidth ? 14 : 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF0F9D8A)
                            : const Color(0xFFE5E7EB),
                        width: selected ? 1.6 : 1,
                      ),
                      color: selected
                          ? const Color(0xFFF1FCF9)
                          : const Color(0xFFFFFFFF),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          _categoryIcon(category.key),
                          size: compactWidth ? 28 : 30,
                          color: const Color(0xFF0F9D8A),
                        ),
                        SizedBox(height: compactWidth ? 12 : 16),
                        Text(
                          category.label,
                          maxLines: crossAxisCount == 1 ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compactWidth ? 15 : 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            _categorySubtitle(category.key),
                            maxLines: crossAxisCount == 1 ? 2 : 4,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compactWidth ? 11.5 : 12,
                              color: const Color(0xFF6B7280),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 18),
        _buildBottomActions(
          onBack: () => setState(() => _currentStep = 1),
          primaryLabel: 'Next',
          primaryIcon: Icons.arrow_forward_rounded,
          onPrimary: _selectedCategory == null
              ? null
              : () => setState(() => _currentStep = 3),
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Step 3 of 3 - Add details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _selectedCategory?.key == 'wrong_items'
              ? 'Tell us which item(s) you received instead.'
              : 'Provide the key details so our support team can review faster.',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF6B7280),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),
        _buildInputLabel('Complaint title or summary'),
        const SizedBox(height: 8),
        TextField(
          controller: _complaintTextController,
          textInputAction: TextInputAction.next,
          decoration: _inputDecoration(
            hintText: _selectedCategory?.key == 'wrong_items'
                ? 'Describe the wrong items you received'
                : 'Write a short summary of the problem',
          ),
        ),
        const SizedBox(height: 16),
        _buildInputLabel('Attach a photo (optional)'),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _pickPhoto,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF0F9D8A), width: 1.3),
              color: const Color(0xFFF6FFFD),
            ),
            child: Column(
              children: [
                Icon(
                  _selectedPhoto == null
                      ? Icons.cloud_upload_rounded
                      : Icons.image_outlined,
                  size: 36,
                  color: const Color(0xFF0F9D8A),
                ),
                const SizedBox(height: 10),
                Text(
                  _selectedPhoto == null
                      ? 'Tap to upload a photo of the issue'
                      : _selectedPhoto!.path.split('/').last,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedPhoto == null
                      ? 'JPG or PNG works best'
                      : 'Tap again if you want to replace it',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInputLabel('Tell us more (optional)'),
        const SizedBox(height: 8),
        TextField(
          controller: _detailController,
          maxLines: 5,
          decoration: _inputDecoration(
            hintText: 'Add any extra detail that will help support review it.',
          ),
        ),
        const SizedBox(height: 18),
        _buildBottomActions(
          onBack: () => setState(() => _currentStep = 2),
          primaryLabel: _isSubmitting ? 'Submitting...' : 'Submit Complaint',
          primaryIcon: Icons.send_rounded,
          onPrimary: _isSubmitting ? null : _submitComplaint,
        ),
      ],
    );
  }

  Widget _buildBottomActions({
    required VoidCallback onBack,
    required String primaryLabel,
    required IconData primaryIcon,
    required VoidCallback? onPrimary,
  }) {
    final compactWidth = _isCompactWidth(context);

    if (compactWidth) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: _buildPrimaryButton(
              label: primaryLabel,
              icon: primaryIcon,
              onTap: onPrimary,
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Back'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildPrimaryButton(
            label: primaryLabel,
            icon: primaryIcon,
            onTap: onPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6B6B),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFFCA5A5),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EFEA)),
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE8F8F5),
            ),
            child: const Icon(
              Icons.check_rounded,
              size: 48,
              color: Color(0xFF0F9D8A),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Complaint Submitted!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _successMessage ??
                'We received your complaint and our support team will review it shortly.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.55,
            ),
          ),
          const SizedBox(height: 24),
          _buildPrimaryButton(
            label: 'Track My Complaints',
            icon: Icons.receipt_long_outlined,
            onTap: () => setState(() {
              _successMessage = null;
              _showHistory = true;
            }),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _resetFlow,
            child: const Text('File Another Complaint'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryView() {
    if (_complaints.isEmpty) {
      return _buildSoftEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'No complaints yet',
        subtitle:
            'Your submitted complaints will appear here with their latest status.',
      );
    }

    return Column(
      children: _complaints.map(_buildComplaintHistoryCard).toList(),
    );
  }

  Widget _buildComplaintHistoryCard(ComplaintHistoryItem complaint) {
    final photoUrl = complaint.photos.isNotEmpty
        ? ApiConstants.getImageUrl(complaint.photos.first)
        : null;
    final statusColor = _statusColor(complaint.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4EFEA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '# ${complaint.orderCode}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F9D8A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint.createdAt,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
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
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _statusLabel(complaint.status).toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            complaint.category,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            complaint.complaintText,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.45,
            ),
          ),
          if (complaint.conditionalDetail.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              complaint.conditionalDetail,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
                height: 1.45,
              ),
            ),
          ],
          if (photoUrl != null && photoUrl.isNotEmpty) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(
                photoUrl,
                height: 120,
                width: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 120,
                  height: 120,
                  color: const Color(0xFFF3F4F6),
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
          ],
          if ((complaint.replyMessage ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1FBF9),
                borderRadius: BorderRadius.circular(16),
                border: const Border(
                  left: BorderSide(color: Color(0xFF0F9D8A), width: 3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.support_agent_rounded,
                        size: 18,
                        color: Color(0xFF0F9D8A),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Support Team replied',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      if ((complaint.replyAt ?? '').trim().isNotEmpty)
                        Text(
                          complaint.replyAt!,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complaint.replyMessage!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSoftEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE4EFEA)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: const Color(0xFF0F9D8A)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 52,
              color: Color(0xFFFF6B6B),
            ),
            const SizedBox(height: 14),
            const Text(
              'Could not load complaint data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            _buildPrimaryButton(
              label: 'Try Again',
              icon: Icons.refresh_rounded,
              onTap: _loadComplaintData,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF0F9D8A), width: 1.4),
      ),
    );
  }
}
