// lib/presentation/update_testing_screen.dart

import 'package:flutter/material.dart';
import '../../core/services/update_manager.dart';
import '../../data/models/update_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateTestingScreen extends StatefulWidget {
  const UpdateTestingScreen({super.key});

  @override
  State<UpdateTestingScreen> createState() => _UpdateTestingScreenState();
}

class _UpdateTestingScreenState extends State<UpdateTestingScreen> {
  late UpdateManager _updateManager;
  bool _isLoading = false;
  String _lastResult = '';
  Map<String, dynamic> _appInfo = {};

  @override
  void initState() {
    super.initState();
    _initUpdateManager();
    _loadAppInfo();
  }

  void _initUpdateManager() {
    _updateManager = UpdateManager(
      context: context,
      apiUrl: '${UpdateConfig.baseUrl}${UpdateConfig.versionEndpoint}',
      debugMode: true,
    );
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _appInfo = {
          'App Name': packageInfo.appName,
          'Package Name': packageInfo.packageName,
          'Version': packageInfo.version,
          'Build Number': packageInfo.buildNumber,
          'Last Check': _formatTimestamp(
            prefs.getInt(UpdateConfig.prefLastCheckTime),
          ),
          'Dismissed Version':
          prefs.getInt(UpdateConfig.prefDismissedVersion)?.toString() ??
              'None',
        };
      });
    } catch (e) {
      debugPrint('Error loading app info: $e');
    }
  }

  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return 'Never';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  Future<void> _testUpdate() async {
    setState(() {
      _isLoading = true;
      _lastResult = '';
    });

    try {
      final result = await _updateManager.checkForUpdates();

      setState(() {
        _lastResult = '''
            Decision: ${result.decision.name}
            Should Update: ${result.shouldUpdate}
            Forced: ${result.isForced}
            Message: ${result.message ?? 'None'}
            Grace Days: ${result.graceDaysRemaining ?? 'N/A'}
            Version Info: ${result.versionInfo != null ? 'Present' : 'None'}
          ''';
      });

      if (result.shouldUpdate) {
        await _updateManager.showUpdateUI(result);
      }
    } catch (e) {
      setState(() {
        _lastResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      await _loadAppInfo();
    }
  }

  Future<void> _clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(UpdateConfig.prefLastCheckTime);
    await prefs.remove(UpdateConfig.prefDismissedVersion);
    await _resetGracePeriod();
    await _loadAppInfo();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences cleared!')),
      );
    }
  }

  Future<void> _resetGracePeriod() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();

    for (var key in keys) {
      if (key.startsWith(UpdateConfig.prefGracePrefix)) {
        await prefs.remove(key);
      }
    }

    await _loadAppInfo();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grace period reset!')),
      );
    }
  }

  Future<void> _resetDismissedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(UpdateConfig.prefDismissedVersion);
    await _loadAppInfo();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dismissed version reset!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Testing'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'App Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  ..._appInfo.entries.map(
                        (entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 140,
                            child: Text(
                              '${entry.key}:',
                              style:
                              const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: Text(entry.value.toString()),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Test Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.science, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Test Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _testUpdate,
                      icon: _isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),    
                                            
                      )
                          : const Icon(Icons.play_arrow),
                      label: const Text('Run Update Check'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _resetGracePeriod,
                      icon: const Icon(Icons.timer_off),
                      label: const Text('Reset Grace Period'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _resetDismissedVersion,
                      icon: const Icon(Icons.replay),
                      label: const Text('Reset Dismissed Version'),
                    ),
                  ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _clearPreferences,
                      icon: const Icon(Icons.delete_sweep),
                      label: const Text('Clear All Preferences'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Last Result
          if (_lastResult.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.assignment, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        const Text(
                          'Last Test Result',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _lastResult,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Configuration
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.settings, color: Colors.purple[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Configuration',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildConfigRow(
                      'API URL',
                      '${UpdateConfig.baseUrl}${UpdateConfig.versionEndpoint}'),
                  _buildConfigRow('Check Interval',
                      '${UpdateConfig.minCheckIntervalHours} hours'),
                  _buildConfigRow(
                      'Default Grace', '${UpdateConfig.defaultGracePeriod} days'),
                  _buildConfigRow('API Timeout',
                      '${UpdateConfig.apiTimeoutSeconds} seconds'),
                  _buildConfigRow('iOS App ID', UpdateConfig.iosAppStoreId),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Mock Scenarios
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.code, color: Colors.teal[700]),
                      const SizedBox(width: 8),
                      const Text(
                        'Mock Scenarios',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  const Text(
                    'You can test these scenarios from your API:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  _buildScenarioChip('Kill Switch', '{"kill_switch": true}'),
                  _buildScenarioChip('Force Update',
                      '{"force_update_versions": [current_version]}'),
                  _buildScenarioChip('Below Min',
                      '{"min_supported_version": current_version+1}'),
                  _buildScenarioChip('Grace Period',
                      '{"grace_period_days": 1}'),
                  _buildScenarioChip(
                      'Optional', '{"update_type": "OPTIONAL"}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioChip(String name, String code) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.teal.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.teal.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              code,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
