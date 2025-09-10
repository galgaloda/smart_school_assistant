import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AdminMenuSettingsScreen extends StatefulWidget {
  const AdminMenuSettingsScreen({super.key});

  @override
  State<AdminMenuSettingsScreen> createState() => _AdminMenuSettingsScreenState();
}

class _AdminMenuSettingsScreenState extends State<AdminMenuSettingsScreen> {
  late Box _settingsBox;
  bool _isLoading = true;

  // Menu items that can be controlled
  final List<String> _menuItems = [
    'inventory_management',
    'data_records',
    'semester_management',
    'assessment_customization',
    'results_ranking',
    'backup_restore',
    'advanced_reports',
    'analytics_dashboard',
    'management_hub',
  ];

  // User roles
  final List<String> _userRoles = ['admin', 'teacher', 'student', 'staff', 'parent'];

  @override
  void initState() {
    super.initState();
    _initializeSettings();
  }

  Future<void> _initializeSettings() async {
    _settingsBox = await Hive.openBox('menu_settings');
    setState(() {
      _isLoading = false;
    });
  }

  bool _isMenuItemVisible(String menuItem, String role) {
    final key = '${menuItem}_$role';
    return _settingsBox.get(key, defaultValue: _getDefaultVisibility(menuItem, role));
  }

  bool _getDefaultVisibility(String menuItem, String role) {
    // Default visibility rules
    switch (role) {
      case 'admin':
        return true; // Admin sees everything
      case 'teacher':
        return ['data_records', 'assessment_customization', 'results_ranking', 'advanced_reports'].contains(menuItem);
      case 'student':
        return ['results_ranking'].contains(menuItem);
      case 'staff':
        return ['data_records', 'results_ranking'].contains(menuItem);
      case 'parent':
        return ['results_ranking'].contains(menuItem);
      default:
        return false;
    }
  }

  void _toggleMenuItemVisibility(String menuItem, String role) {
    final key = '${menuItem}_$role';
    final currentValue = _isMenuItemVisible(menuItem, role);
    _settingsBox.put(key, !currentValue);
    setState(() {});
  }

  String _getMenuItemDisplayName(String menuItem) {
    switch (menuItem) {
      case 'inventory_management':
        return 'Inventory Management';
      case 'data_records':
        return 'Data Records';
      case 'semester_management':
        return 'Semester Management';
      case 'assessment_customization':
        return 'Assessment Customization';
      case 'results_ranking':
        return 'Results & Rankings';
      case 'backup_restore':
        return 'Backup & Restore';
      case 'advanced_reports':
        return 'Advanced Reports';
      case 'analytics_dashboard':
        return 'Analytics Dashboard';
      case 'management_hub':
        return 'Management Hub';
      default:
        return menuItem;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'teacher':
        return 'Teacher';
      case 'student':
        return 'Student';
      case 'staff':
        return 'Staff';
      case 'parent':
        return 'Parent';
      default:
        return role;
    }
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
        title: const Text('Menu Visibility Settings'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Control which menu items are visible to different user roles',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ..._userRoles.map((role) => _buildRoleSection(role)),
        ],
      ),
    );
  }

  Widget _buildRoleSection(String role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getRoleDisplayName(role),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            ..._menuItems.map((menuItem) => _buildMenuItemToggle(menuItem, role)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemToggle(String menuItem, String role) {
    final isVisible = _isMenuItemVisible(menuItem, role);
    final isDefault = _getDefaultVisibility(menuItem, role);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _getMenuItemDisplayName(menuItem),
              style: TextStyle(
                color: isVisible ? Colors.black : Colors.grey,
              ),
            ),
          ),
          if (isDefault)
            const Text(
              '(Default)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.green,
              ),
            ),
          Switch(
            value: isVisible,
            onChanged: (value) {
              _toggleMenuItemVisibility(menuItem, role);
            },
            activeColor: Colors.indigo,
          ),
        ],
      ),
    );
  }
}