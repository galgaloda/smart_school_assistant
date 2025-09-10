import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/sync_service.dart';
import '../services/firebase_service.dart';
import '../models/user_role.dart';
import '../main.dart';
import '../services/menu_visibility_service.dart';
import '../models/user_role.dart' as user_role;
import 'admin_menu_settings_screen.dart';
import 'login_screen.dart';
import 'teacher_assistant/class_selection_screen.dart';
import 'timetable/timetable_screen.dart';
import 'reports/report_generator_hub.dart';
import 'settings_screen.dart';
import 'inventory_screen.dart';
import 'data_records_screen.dart';
import 'semester_management_screen.dart';
import 'assessment_customization_screen.dart';
import 'results_ranking_screen.dart';
import 'backup_restore_screen.dart';
import 'advanced_reports_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'management_hub_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isOnline = true;
  bool _isSyncing = false;
  String _syncStatus = 'Ready';
  DateTime? _lastSyncTime;

  static const List<Widget> _widgetOptions = <Widget>[
    ClassSelectionScreen(),
    TimetableScreen(),
    ReportGeneratorHub(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeSyncStatus();
    _monitorConnectivity();
    // Debug: Check current user
    final isAuthenticated = FirebaseService.isAuthenticated;
    print('User authenticated in HomeScreen: $isAuthenticated');
    if (isAuthenticated) {
      final currentUser = user_role.AccessControlManager.getCurrentUser();
      print('User role: ${currentUser?.role}');
      print('User email: ${currentUser?.email}');
    } else {
      print('No current user authenticated');
    }
  }

  Future<void> _initializeSyncStatus() async {
    final lastSyncTime = SyncService.getLastSyncTime();
    final isOnline = await SyncService.isOnline();

    setState(() {
      _lastSyncTime = lastSyncTime;
      _isOnline = isOnline;
      _syncStatus = _isOnline ? 'Ready' : 'Offline';
    });
  }

  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      setState(() {
        _isOnline = result != ConnectivityResult.none;
        _syncStatus = _isOnline ? 'Ready' : 'Offline';
      });
    });
  }

  Future<void> _performSync() async {
    if (!_isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No internet connection. Sync requires online access.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSyncing = true;
      _syncStatus = 'Syncing...';
    });

    try {
      final result = await SyncService.performFullSync();

      setState(() {
        _isSyncing = false;
        _syncStatus = result.success ? 'Synced' : 'Sync Failed';
        _lastSyncTime = DateTime.now();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      setState(() {
        _isSyncing = false;
        _syncStatus = 'Sync Failed';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sync failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _formatLastSyncTime(DateTime syncTime) {
    final now = DateTime.now();
    final difference = now.difference(syncTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${syncTime.day}/${syncTime.month}/${syncTime.year}';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _sendFeedback(BuildContext context) async {
    const String feedbackMessage =
        'Smart School Assistant Feedback:\n\n'
        'Please share your feedback about the app:\n\n'
        '• What features do you like?\n'
        '• What improvements would you suggest?\n'
        '• Any issues you encountered?\n\n'
        'Email: feedback@smartschool.com\n'
        'Version: 1.0.0';

    await Share.share(
      feedbackMessage,
      subject: 'Smart School Assistant Feedback',
    );
  }

  Future<void> _shareApp(BuildContext context) async {
    const String appLink = 'https://play.google.com/store/apps/details?id=com.example.smart_school_assistant';
    const String message = 'Check out Smart School Assistant - A comprehensive school management app!\n\nDownload now: $appLink';

    await Share.share(message, subject: 'Smart School Assistant App');
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Smart School Assistant',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.school, size: 48),
      applicationLegalese: '© 2024 Smart School Assistant\nAll rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Smart School Assistant is a comprehensive school management application designed to help teachers and administrators manage students, classes, attendance, and generate reports efficiently.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Features include:\n'
          '• Student Management\n'
          '• Attendance Tracking\n'
          '• Grade Management\n'
          '• Report Generation\n'
          '• Analytics Dashboard\n'
          '• Photo Management\n'
          '• Multi-language Support',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String? _getCurrentUserRole() {
    final currentUser = user_role.AccessControlManager.getCurrentUser();
    if (currentUser == null) return null;

    final role = currentUser.role.toString().split('.').last; // Convert enum to string
    print('Current user role: $role');
    return role;
  }

  String _getCurrentUserDisplayName() {
    final currentUser = user_role.AccessControlManager.getCurrentUser();
    if (currentUser == null) return 'Guest';

    // Use display name if available, otherwise use email prefix
    if (currentUser.displayName.isNotEmpty) {
      return currentUser.displayName;
    }

    // Extract name from email (before @)
    final email = currentUser.email;
    if (email.contains('@')) {
      return email.split('@')[0];
    }

    return 'User';
  }

  bool _isMenuItemVisible(String menuItemKey) {
    final userRole = _getCurrentUserRole();
    if (userRole == null) {
      print('No user role found for menu visibility check');
      return false;
    }

    // For admin users, always show all menu items (simplified logic)
    if (userRole == 'admin') {
      print('Admin user detected, showing menu item: $menuItemKey');
      return true;
    }

    // Check both permission and visibility settings for non-admin users
    final hasPermission = _checkPermissionForMenuItem(menuItemKey);
    final isVisible = MenuVisibilityService.isMenuItemVisible(menuItemKey, userRole);

    print('Menu item $menuItemKey - Role: $userRole, Permission: $hasPermission, Visibility: $isVisible');
    return hasPermission && isVisible;
  }

  bool _checkPermissionForMenuItem(String menuItemKey) {
    final role = _getCurrentUserRole();
    if (role == null) return false;

    switch (menuItemKey) {
      case 'inventory_management':
        return ['admin', 'principal'].contains(role);
      case 'data_records':
        return ['admin', 'principal', 'teacher', 'staff'].contains(role);
      case 'semester_management':
        return ['admin', 'principal'].contains(role);
      case 'assessment_customization':
        return ['admin', 'principal', 'teacher'].contains(role);
      case 'results_ranking':
        return ['admin', 'principal', 'teacher', 'staff', 'parent', 'student'].contains(role);
      case 'backup_restore':
        return ['admin', 'principal'].contains(role);
      case 'advanced_reports':
        return ['admin', 'principal', 'teacher'].contains(role);
      case 'analytics_dashboard':
        return ['admin', 'principal'].contains(role);
      case 'management_hub':
        return ['admin', 'principal'].contains(role);
      default:
        return false;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text(
          'Are you sure you want to logout? You will need to login again to access the app.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close dialog immediately for better UX
              Navigator.of(context).pop();

              try {
                // Clear current user from AccessControlManager first
                AccessControlManager.setCurrentUser(null);
                print('AccessControlManager cleared');

                // Sign out from Firebase (this is the main async operation)
                await FirebaseService.signOut();
                print('Firebase sign out successful');

                // Force app to rebuild and check login state
                if (appKey.currentState != null) {
                  appKey.currentState!.setState(() {});
                }

                // Navigate to LoginScreen directly and clear navigation stack
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );

                // Show success message after navigation
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                });
              } catch (e) {
                print('Error during logout: $e');
                // Even if there's an error, we've already cleared the local state
                // Force navigation anyway
                if (appKey.currentState != null) {
                  appKey.currentState!.setState(() {});
                }
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );

                // Show error message after navigation
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout completed with warning: $e'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                });
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Check current user at build time
    final isAuthenticated = FirebaseService.isAuthenticated;
    print('User authenticated at build time: $isAuthenticated');
    if (isAuthenticated) {
      final currentUser = user_role.AccessControlManager.getCurrentUser();
      print('User role at build time: ${currentUser?.role}');
      print('User email at build time: ${currentUser?.email}');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart School Assistant'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          // Sync Status Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: _isOnline
                  ? (_isSyncing ? Colors.orange : Colors.green)
                  : Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  _isSyncing
                      ? Icons.sync
                      : (_isOnline ? Icons.cloud_done : Icons.cloud_off),
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  _syncStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Sync Button
          IconButton(
            icon: Icon(
              _isSyncing ? Icons.sync : Icons.sync_alt,
              color: _isOnline ? Colors.white : Colors.grey,
            ),
            onPressed: _isOnline && !_isSyncing ? _performSync : null,
            tooltip: _isOnline ? 'Sync with cloud' : 'Offline - sync unavailable',
          ),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.indigo,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Smart School Assistant',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'School Management System',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // User Info and Logout in Drawer Header
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: double.infinity,
                      minHeight: 40,
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // User Name
                          Flexible(
                            fit: FlexFit.loose,
                            child: Text(
                              _getCurrentUserDisplayName(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Logout Button
                          IconButton(
                            icon: const Icon(Icons.logout, size: 20),
                            color: Colors.white,
                            onPressed: () => _showLogoutDialog(context),
                            tooltip: 'Logout',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Sync Status in Drawer
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? (_isSyncing ? Colors.orange.withOpacity(0.8) : Colors.green.withOpacity(0.8))
                          : Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isSyncing
                              ? Icons.sync
                              : (_isOnline ? Icons.cloud_done : Icons.cloud_off),
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _syncStatus,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_lastSyncTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Last sync: ${_formatLastSyncTime(_lastSyncTime!)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              subtitle: const Text('Dark mode, language, guide'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            if (_getCurrentUserRole() == 'admin') ...[
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Menu Settings'),
                subtitle: const Text('Control menu visibility for user roles'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminMenuSettingsScreen()),
                  );
                },
              ),
            ],
            const Divider(),
            if (_isMenuItemVisible('inventory_management')) ...[
              ListTile(
                leading: const Icon(Icons.inventory),
                title: const Text('Inventory Management'),
                subtitle: const Text('Manage school resources'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InventoryScreen()),
                  );
                },
              ),
              const Divider(),
            ],
            if (_isMenuItemVisible('data_records')) ...[
              ListTile(
                leading: const Icon(Icons.folder),
                title: const Text('Data Records'),
                subtitle: const Text('School documents and records'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DataRecordsScreen()),
                  );
                },
              ),
              const Divider(),
            ],
            if (_isMenuItemVisible('semester_management')) ...[
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Semester Management'),
                subtitle: const Text('Manage academic semesters'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SemesterManagementScreen()),
                  );
                },
              ),
            ],
            if (_isMenuItemVisible('assessment_customization')) ...[
              ListTile(
                leading: const Icon(Icons.assessment),
                title: const Text('Assessment Customization'),
                subtitle: const Text('Define assessments with weights'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AssessmentCustomizationScreen()),
                  );
                },
              ),
              const Divider(),
            ],
            if (_isMenuItemVisible('results_ranking')) ...[
              ListTile(
                leading: const Icon(Icons.leaderboard),
                title: const Text('Results & Rankings'),
                subtitle: const Text('View student grades and rankings'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ResultsRankingScreen()),
                  );
                },
              ),
              const Divider(),
            ],
            if (_isMenuItemVisible('backup_restore')) ...[
              ListTile(
                leading: const Icon(Icons.backup),
                title: const Text('Backup & Restore'),
                subtitle: const Text('Backup and restore app data'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BackupRestoreScreen()),
                  );
                },
              ),
              const Divider(),
            ],
            if (_isMenuItemVisible('advanced_reports')) ...[
              ListTile(
                leading: const Icon(Icons.analytics),
                title: const Text('Advanced Reports'),
                subtitle: const Text('Professional report cards and analytics'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdvancedReportsScreen()),
                  );
                },
              ),
            ],
            if (_isMenuItemVisible('analytics_dashboard')) ...[
              ListTile(
                leading: const Icon(Icons.dashboard),
                title: const Text('Analytics Dashboard'),
                subtitle: const Text('Visual data insights and KPIs'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnalyticsDashboardScreen()),
                  );
                },
              ),
              const Divider(),
            ],
            if (_isMenuItemVisible('management_hub')) ...[
              ListTile(
                leading: const Icon(Icons.admin_panel_settings),
                title: const Text('Management Hub'),
                subtitle: const Text('Enhanced management tools'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ManagementHubScreen()),
                  );
                },
              ),
            ],
            const Divider(),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: const Icon(Icons.feedback),
              title: const Text('Feedback'),
              subtitle: const Text('Send feedback and suggestions'),
              onTap: () {
                Navigator.pop(context);
                _sendFeedback(context);
              },
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              subtitle: const Text('Share Smart School Assistant'),
              onTap: () {
                Navigator.pop(context);
                _shareApp(context);
              },
            ),
            const Divider(),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              leading: const Icon(Icons.info),
              title: const Text('About'),
              subtitle: const Text('App information and version'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
          ],
        ),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Teacher Assistant',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Timetable',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: 'Reports',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        onTap: _onItemTapped,
      ),
    );
  }
}
