//lib/presentation/widgets/update_widgets.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/update_models.dart';

// Custom Update Dialog Widget
class UpdateDialog extends StatelessWidget {
  final String title;
  final String message;
  final VersionInfo? versionInfo;
  final bool isForced;
  final bool isKillSwitch;
  final int? graceDaysLeft;
  final VoidCallback onUpdate;
  final VoidCallback? onDismiss;

  const UpdateDialog({
    super.key,
    required this.title,
    required this.message,
    this.versionInfo,
    this.isForced = false,
    this.isKillSwitch = false,
    this.graceDaysLeft,
    required this.onUpdate,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isForced,
      child: AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              _getIcon(),
              color: _getIconColor(),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main message
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),

              // Version info
              if (versionInfo != null) ...[
                const SizedBox(height: 16),
                _buildVersionInfo(),
              ],

              // Grace period indicator
              if (graceDaysLeft != null && graceDaysLeft! > 0) ...[
                const SizedBox(height: 16),
                _buildGracePeriodIndicator(),
              ],

              // Kill switch warning
              if (isKillSwitch) ...[
                const SizedBox(height: 16),
                _buildKillSwitchWarning(),
              ],

              // Release notes
              if (versionInfo != null) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                _buildReleaseNotes(),
              ],
            ],
          ),
        ),
        actions: _buildActions(context),
      ),
    );
  }

  IconData _getIcon() {
    if (isKillSwitch) return Icons.block;
    if (isForced) return Icons.system_update_alt;
    return Icons.new_releases;
  }

  Color _getIconColor() {
    if (isKillSwitch) return Colors.red;
    if (isForced) return Colors.orange;
    return Colors.blue;
  }

  Widget _buildVersionInfo() {
    final isAndroid = Platform.isAndroid;
    final platformName = isAndroid ? 'Android' : 'iOS';
    final versionName = versionInfo!.getVersionName(isAndroid);
    final versionCode = versionInfo!.getVersionCode(isAndroid);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Version ($platformName): ${versionName ?? 'N/A'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Version Code: ${versionCode ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGracePeriodIndicator() {
    final percentage = graceDaysLeft! / 7.0;
    final color = percentage > 0.5
        ? Colors.green
        : percentage > 0.25
        ? Colors.orange
        : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                '$graceDaysLeft days left',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKillSwitchWarning() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning, color: Colors.red, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'App Temporarily Disabled',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReleaseNotes() {
    final isAndroid = Platform.isAndroid;
    final notes = versionInfo!.getReleaseNotes(isAndroid);

    if (notes == null || notes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.star, size: 18, color: Colors.amber[700]),
            const SizedBox(width: 6),
            const Text(
              "What's New:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            )
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            notes,
            style: const TextStyle(fontSize: 13, height: 1.5),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    if (isForced) {
      return [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onUpdate,
            icon: const Icon(Icons.download),
            label: const Text(
              'Update Now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isKillSwitch ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ];
    }

    return [
      TextButton(
        onPressed: onDismiss,
        child: const Text('Skip', style: TextStyle(fontSize: 16)),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: ElevatedButton.icon(
          onPressed: onUpdate,
          icon: const Icon(Icons.download),
          label: const Text('Update'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ];
  }
}

// Compact Update Banner (Alternative to Dialog)
class UpdateBanner extends StatelessWidget {
  final String message;
  final VoidCallback onTap;
  final VoidCallback? onDismiss;
  final bool isDismissible;

  const UpdateBanner({
    super.key,
    required this.message,
    required this.onTap,
    this.onDismiss,
    this.isDismissible = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.system_update,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'New Update Available',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isDismissible && onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: onDismiss,
                  )
                else
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Persistent Update Snackbar
class UpdateSnackbar {
  static void show({
    required BuildContext context,
    required String message,
    required VoidCallback onUpdate,
    VoidCallback? onDismiss,
    bool isDismissible = true,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(days: 1), // Persistent
        action: SnackBarAction(
          label: 'Update',
          textColor: Colors.yellow,
          onPressed: onUpdate,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.blue[800],
      ),
    );
  }
}