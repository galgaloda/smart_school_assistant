import 'package:hive_flutter/hive_flutter.dart';

class MenuVisibilityService {
  static late Box _settingsBox;

  static Future<void> initialize() async {
    _settingsBox = await Hive.openBox('menu_settings');
  }

  static bool isMenuItemVisible(String menuItem, String userRole) {
    final key = '${menuItem}_$userRole';
    return _settingsBox.get(key, defaultValue: _getDefaultVisibility(menuItem, userRole));
  }

  static bool _getDefaultVisibility(String menuItem, String role) {
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

  static Future<void> setMenuItemVisibility(String menuItem, String userRole, bool visible) async {
    final key = '${menuItem}_$userRole';
    await _settingsBox.put(key, visible);
  }

  static Future<void> resetToDefaults(String userRole) async {
    final menuItems = [
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

    for (final menuItem in menuItems) {
      final key = '${menuItem}_$userRole';
      final defaultVisibility = _getDefaultVisibility(menuItem, userRole);
      await _settingsBox.put(key, defaultVisibility);
    }
  }
}