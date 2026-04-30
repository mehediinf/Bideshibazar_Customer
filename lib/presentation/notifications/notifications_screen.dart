//lib/presentation/notifications/notifications_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/notification_item.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/app_error_helper.dart';

class NotificationsScreen extends StatefulWidget {
  final String? authToken;
  final String baseUrl;

  const NotificationsScreen({
    super.key,
    required this.authToken,
    required this.baseUrl,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const String _keyTabState = 'selected_tab';

  bool _showingAll = true;
  bool _isLoading = false;

  final List<NotificationItem> _masterList = [];
  final List<NotificationItem> _shownList = [];

  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService(
      baseUrl: widget.baseUrl,
      token: widget.authToken,
    );
    _loadSavedTabState();
    _loadNotifications();
  }

  Future<void> _loadSavedTabState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTab = prefs.getString(_keyTabState) ?? 'all';
    setState(() {
      _showingAll = savedTab == 'all';
    });
  }

  Future<void> _saveTabState(String tab) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTabState, tab);
  }

  Future<void> _loadNotifications() async {
    if (widget.authToken == null || widget.authToken!.isEmpty) {
      _showSnackBar('Please login to view notifications');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _notificationService.getNotifications();
      final notifications = result['notifications'] as List<NotificationItem>;

      setState(() {
        _masterList.clear();
        _masterList.addAll(notifications);
        _isLoading = false;
        _updateShownList();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar(AppErrorHelper.toUserMessage(e));
    }
  }

  void _updateShownList() {
    _shownList.clear();
    if (_showingAll) {
      _shownList.addAll(_masterList);
    } else {
      _shownList.addAll(_masterList.where((item) => !item.isRead));
    }
  }

  Future<void> _markAsRead(NotificationItem item) async {
    try {
      await _notificationService.markAsRead(item.id);
      setState(() {
        if (!_showingAll) {
          _updateShownList();
        }
      });
    } catch (e) {
      _showSnackBar(AppErrorHelper.toUserMessage(e));
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final success = await _notificationService.markAllAsRead();
      if (success) {
        setState(() {
          for (var item in _masterList) {
            item.isRead = true;
          }
          _updateShownList();
        });
        _showSnackBar('All marked as read');
      }
    } catch (e) {
      _showSnackBar(AppErrorHelper.toUserMessage(e));
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 4,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF212121)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text(
              'Mark Read',
              style: TextStyle(
                color: Color(0xFF9C27B0),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tabs
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTab('All', _showingAll, () {
                  setState(() {
                    _showingAll = true;
                    _updateShownList();
                  });
                  _saveTabState('all');
                }),
                const SizedBox(width: 16),
                _buildTab('Unread', !_showingAll, () {
                  setState(() {
                    _showingAll = false;
                    _updateShownList();
                  });
                  _saveTabState('unread');
                }),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _shownList.isEmpty
                ? _buildEmptyView()
                : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _shownList.length,
                itemBuilder: (context, index) {
                  return _NotificationItemWidget(
                    item: _shownList[index],
                    onTap: (item) {
                      if (!item.isRead) {
                        _markAsRead(item);
                        setState(() {
                          item.isRead = true;
                        });
                      }
                      setState(() {
                        item.isExpanded = !item.isExpanded;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE1BEE7) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF9C27B0) : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            _showingAll ? 'No notifications yet' : 'No unread notifications',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationItemWidget extends StatelessWidget {
  final NotificationItem item;
  final Function(NotificationItem) onTap;

  const _NotificationItemWidget({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => onTap(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Unread dot
                  if (!item.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 6, right: 8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  // Title and time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                            item.isRead ? FontWeight.normal : FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand icon
                  AnimatedRotation(
                    turns: item.isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              // Expandable content
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: item.isExpanded
                    ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    item.fullText,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
