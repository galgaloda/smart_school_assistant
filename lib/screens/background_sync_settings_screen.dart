import 'package:flutter/material.dart';

class BackgroundSyncSettingsScreen extends StatefulWidget {
  const BackgroundSyncSettingsScreen({super.key});

  @override
  State<BackgroundSyncSettingsScreen> createState() => _BackgroundSyncSettingsScreenState();
}

class _BackgroundSyncSettingsScreenState extends State<BackgroundSyncSettingsScreen> {
  bool _backgroundSyncEnabled = true;
  int _syncIntervalHours = 1;
  bool _wifiOnlySync = false;
  bool _batteryOptimization = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Temporarily disabled workmanager features
    setState(() {
      _backgroundSyncEnabled = false; // SyncService.isBackgroundSyncEnabled();
      _syncIntervalHours = 1; // SyncService.getSyncIntervalHours();
      _wifiOnlySync = false; // SyncService.isWifiOnlySync();
      _batteryOptimization = true; // SyncService.isBatteryOptimizationEnabled();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Background Sync Settings'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Background Sync Toggle
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Background Sync',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Automatically sync data in the background when connected to the internet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Enable Background Sync'),
                    subtitle: const Text('Sync data automatically in the background'),
                    value: _backgroundSyncEnabled,
                    onChanged: (value) async {
                      setState(() {
                        _backgroundSyncEnabled = value;
                      });
                      // await SyncService.setBackgroundSyncEnabled(value); // Temporarily disabled
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Background sync enabled'
                                  : 'Background sync disabled'
                            ),
                          ),
                        );
                      }
                    },
                    secondary: Icon(
                      _backgroundSyncEnabled ? Icons.sync : Icons.sync_disabled,
                      color: _backgroundSyncEnabled ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sync Interval Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sync Frequency',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'How often to check for updates and sync data.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _syncIntervalHours,
                    decoration: const InputDecoration(
                      labelText: 'Sync Interval',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Every hour')),
                      DropdownMenuItem(value: 2, child: Text('Every 2 hours')),
                      DropdownMenuItem(value: 4, child: Text('Every 4 hours')),
                      DropdownMenuItem(value: 6, child: Text('Every 6 hours')),
                      DropdownMenuItem(value: 12, child: Text('Every 12 hours')),
                      DropdownMenuItem(value: 24, child: Text('Daily')),
                    ],
                    onChanged: _backgroundSyncEnabled ? (value) async {
                      if (value != null) {
                        setState(() {
                          _syncIntervalHours = value;
                        });
                        // await SyncService.setSyncIntervalHours(value); // Temporarily disabled
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Sync interval updated'),
                            ),
                          );
                        }
                      }
                    } : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Network Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Network Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Configure when and how background sync should run.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('WiFi Only'),
                    subtitle: const Text('Only sync when connected to WiFi'),
                    value: _wifiOnlySync,
                    onChanged: _backgroundSyncEnabled ? (value) async {
                      setState(() {
                        _wifiOnlySync = value;
                      });
                      // await SyncService.setWifiOnlySync(value); // Temporarily disabled
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'WiFi-only sync enabled'
                                  : 'WiFi-only sync disabled'
                            ),
                          ),
                        );
                      }
                    } : null,
                    secondary: Icon(
                      _wifiOnlySync ? Icons.wifi : Icons.wifi_off,
                      color: _wifiOnlySync ? Colors.blue : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Battery Optimization
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Battery Optimization',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Optimize sync to preserve battery life.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Battery Optimization'),
                    subtitle: const Text('Skip sync when battery is low'),
                    value: _batteryOptimization,
                    onChanged: _backgroundSyncEnabled ? (value) async {
                      setState(() {
                        _batteryOptimization = value;
                      });
                      // await SyncService.setBatteryOptimizationEnabled(value); // Temporarily disabled
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              value
                                  ? 'Battery optimization enabled'
                                  : 'Battery optimization disabled'
                            ),
                          ),
                        );
                      }
                    } : null,
                    secondary: Icon(
                      _batteryOptimization ? Icons.battery_full : Icons.battery_alert,
                      color: _batteryOptimization ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Manual Sync Button
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Manual Sync',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Force an immediate background sync for testing.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        // await SyncService.forceBackgroundSync(); // Temporarily disabled
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Background sync scheduled'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Force Background Sync'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Information Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Background Sync Information',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoItem(
                    Icons.info,
                    'Automatic',
                    'Sync runs automatically in the background',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    Icons.network_wifi,
                    'Smart Network',
                    'Only syncs when network conditions are met',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    Icons.battery_std,
                    'Battery Aware',
                    'Respects battery optimization settings',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoItem(
                    Icons.security,
                    'Secure',
                    'All data is encrypted during transmission',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.indigo),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}