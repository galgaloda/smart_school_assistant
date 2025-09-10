import 'dart:async';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import '../models.dart';
import '../models/user_role.dart' as user_role;
import 'firebase_service.dart';
import 'local_auth_service.dart';
import 'comprehensive_auth_service.dart';
import 'encryption_service.dart';

/// Admin User Service
/// Handles comprehensive admin user creation, management, and validation
/// with enhanced security measures and audit trails
class AdminUserService {
  static const String _adminUsersBoxName = 'admin_users';
  static const String _adminSettingsBoxName = 'admin_settings';
  static const String _adminAuditBoxName = 'admin_audit_log';
  static const Duration _adminSessionTimeout = Duration(hours: 8);

  static bool _isInitialized = false;

  /// Initialize the admin user service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.openBox(_adminUsersBoxName);
      await Hive.openBox(_adminSettingsBoxName);
      await Hive.openBox(_adminAuditBoxName);

      _isInitialized = true;
      print('[ADMIN_USER] Admin user service initialized');

    } catch (e) {
      print('[ADMIN_USER] Failed to initialize admin user service: $e');
      rethrow;
    }
  }

  /// Create initial admin user (first-time setup)
  static Future<AdminCreationResult> createInitialAdmin({
    required String email,
    required String password,
    required String displayName,
    required String schoolName,
    String? schoolAddress,
    String? schoolPhone,
    String? adminTitle,
  }) async {
    try {
      // Validate input
      final validation = await _validateAdminCreationInput(
        email: email,
        password: password,
        displayName: displayName,
        schoolName: schoolName,
      );

      if (!validation.isValid) {
        return AdminCreationResult(
          success: false,
          error: validation.errorMessage,
        );
      }

      // Check if admin already exists
      final existingAdmins = await getAllAdmins();
      if (existingAdmins.isNotEmpty) {
        return AdminCreationResult(
          success: false,
          error: 'Admin user already exists. Use addAdditionalAdmin() instead.',
        );
      }

      // Create Firebase user
      final userCredential = await FirebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Create admin user object
      final adminUser = User(
        id: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        role: 'admin',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
        schoolName: schoolName,
        schoolAddress: schoolAddress,
        schoolPhone: schoolPhone,
        adminTitle: adminTitle,
      );

      // Save to local storage
      final usersBox = Hive.box<User>('users');
      await usersBox.put(userCredential.user!.uid, adminUser);

      // Register for local authentication
      await LocalAuthService.registerLocalUser(email, password, adminUser);

      // Save to Firestore with admin-specific data
      await _saveAdminToFirestore(adminUser);

      // Create admin settings
      await _createAdminSettings(userCredential.user!.uid, schoolName);

      // Log admin creation
      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.registrationSuccessful,
        'Initial admin user created: $email',
        userId: userCredential.user!.uid,
      );

      // Audit log
      await _logAdminAction(
        action: 'CREATE_INITIAL_ADMIN',
        userId: userCredential.user!.uid,
        details: {
          'email': email,
          'displayName': displayName,
          'schoolName': schoolName,
        },
      );

      return AdminCreationResult(
        success: true,
        user: adminUser,
        message: 'Admin user created successfully',
      );

    } catch (e) {
      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.registrationFailed,
        'Failed to create initial admin: $e',
      );

      return AdminCreationResult(
        success: false,
        error: 'Failed to create admin user: ${e.toString()}',
      );
    }
  }

  /// Add additional admin user (requires existing admin privileges)
  static Future<AdminCreationResult> addAdditionalAdmin({
    required String email,
    required String password,
    required String displayName,
    required String createdByAdminId,
    String? adminTitle,
    List<String>? permissions,
  }) async {
    try {
      // Verify requesting admin has permission
      final requestingAdmin = await _getAdminById(createdByAdminId);
      if (requestingAdmin == null) {
        return AdminCreationResult(
          success: false,
          error: 'Invalid requesting admin',
        );
      }

      // Check if current user has admin creation permission
      final currentUser = user_role.AccessControlManager.getCurrentUser();
      if (currentUser == null || !currentUser.hasPermission(user_role.Permission.createUsers)) {
        return AdminCreationResult(
          success: false,
          error: 'Insufficient permissions to create admin users',
        );
      }

      // Validate input
      final validation = await _validateAdminCreationInput(
        email: email,
        password: password,
        displayName: displayName,
        schoolName: requestingAdmin.schoolName ?? '',
      );

      if (!validation.isValid) {
        return AdminCreationResult(
          success: false,
          error: validation.errorMessage,
        );
      }

      // Check if email already exists
      final existingUser = await _getUserByEmail(email);
      if (existingUser != null) {
        return AdminCreationResult(
          success: false,
          error: 'User with this email already exists',
        );
      }

      // Create Firebase user
      final userCredential = await FirebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Create admin user object
      final adminUser = User(
        id: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        role: 'admin',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
        schoolName: requestingAdmin.schoolName,
        schoolAddress: requestingAdmin.schoolAddress,
        schoolPhone: requestingAdmin.schoolPhone,
        adminTitle: adminTitle,
        createdBy: createdByAdminId,
      );

      // Save to local storage
      final usersBox = Hive.box<User>('users');
      await usersBox.put(userCredential.user!.uid, adminUser);

      // Register for local authentication
      await LocalAuthService.registerLocalUser(email, password, adminUser);

      // Save to Firestore
      await _saveAdminToFirestore(adminUser);

      // Log admin creation
      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.registrationSuccessful,
        'Additional admin user created: $email by ${requestingAdmin.email}',
        userId: userCredential.user!.uid,
      );

      // Audit log
      await _logAdminAction(
        action: 'CREATE_ADDITIONAL_ADMIN',
        userId: userCredential.user!.uid,
        performedBy: createdByAdminId,
        details: {
          'email': email,
          'displayName': displayName,
          'createdBy': requestingAdmin.email,
        },
      );

      return AdminCreationResult(
        success: true,
        user: adminUser,
        message: 'Additional admin user created successfully',
      );

    } catch (e) {
      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.registrationFailed,
        'Failed to create additional admin: $e',
      );

      return AdminCreationResult(
        success: false,
        error: 'Failed to create additional admin user: ${e.toString()}',
      );
    }
  }

  /// Update admin user
  static Future<AdminUpdateResult> updateAdmin({
    required String adminId,
    required String updatedByAdminId,
    String? displayName,
    String? adminTitle,
    String? schoolAddress,
    String? schoolPhone,
    bool? isActive,
  }) async {
    try {
      // Verify permissions
      final currentUser = user_role.AccessControlManager.getCurrentUser();
      if (currentUser == null || !currentUser.hasPermission(user_role.Permission.editUsers)) {
        return AdminUpdateResult(
          success: false,
          error: 'Insufficient permissions to update admin users',
        );
      }

      // Get admin to update
      final adminUser = await _getAdminById(adminId);
      if (adminUser == null) {
        return AdminUpdateResult(
          success: false,
          error: 'Admin user not found',
        );
      }

      // Create updated user
      final updatedUser = User(
        id: adminUser.id,
        email: adminUser.email,
        displayName: displayName ?? adminUser.displayName,
        role: adminUser.role,
        createdAt: adminUser.createdAt,
        lastLoginAt: adminUser.lastLoginAt,
        isActive: isActive ?? adminUser.isActive,
        schoolName: adminUser.schoolName,
        schoolAddress: schoolAddress ?? adminUser.schoolAddress,
        schoolPhone: schoolPhone ?? adminUser.schoolPhone,
        adminTitle: adminTitle ?? adminUser.adminTitle,
        createdBy: adminUser.createdBy,
        lastUpdated: DateTime.now(),
        updatedBy: updatedByAdminId,
      );

      // Update local storage
      final usersBox = Hive.box<User>('users');
      await usersBox.put(adminId, updatedUser);

      // Update Firestore
      await _updateAdminInFirestore(updatedUser);

      // Update Firebase Auth if display name changed
      if (displayName != null && displayName != adminUser.displayName) {
        final currentFirebaseUser = FirebaseService.currentUser;
        if (currentFirebaseUser != null && currentFirebaseUser.uid == adminId) {
          await currentFirebaseUser.updateDisplayName(displayName);
        }
      }

      // Audit log
      await _logAdminAction(
        action: 'UPDATE_ADMIN',
        userId: adminId,
        performedBy: updatedByAdminId,
        details: {
          'changes': {
            if (displayName != null) 'displayName': displayName,
            if (adminTitle != null) 'adminTitle': adminTitle,
            if (schoolAddress != null) 'schoolAddress': schoolAddress,
            if (schoolPhone != null) 'schoolPhone': schoolPhone,
            if (isActive != null) 'isActive': isActive,
          },
        },
      );

      return AdminUpdateResult(
        success: true,
        user: updatedUser,
        message: 'Admin user updated successfully',
      );

    } catch (e) {
      return AdminUpdateResult(
        success: false,
        error: 'Failed to update admin user: ${e.toString()}',
      );
    }
  }

  /// Deactivate admin user
  static Future<AdminUpdateResult> deactivateAdmin({
    required String adminId,
    required String deactivatedByAdminId,
  }) async {
    return updateAdmin(
      adminId: adminId,
      updatedByAdminId: deactivatedByAdminId,
      isActive: false,
    );
  }

  /// Reactivate admin user
  static Future<AdminUpdateResult> reactivateAdmin({
    required String adminId,
    required String reactivatedByAdminId,
  }) async {
    return updateAdmin(
      adminId: adminId,
      updatedByAdminId: reactivatedByAdminId,
      isActive: true,
    );
  }

  /// Delete admin user
  static Future<AdminDeleteResult> deleteAdmin({
    required String adminId,
    required String deletedByAdminId,
  }) async {
    try {
      // Verify permissions
      final currentUser = user_role.AccessControlManager.getCurrentUser();
      if (currentUser == null || !currentUser.hasPermission(user_role.Permission.deleteUsers)) {
        return AdminDeleteResult(
          success: false,
          error: 'Insufficient permissions to delete admin users',
        );
      }

      // Prevent self-deletion
      if (currentUser.id == adminId) {
        return AdminDeleteResult(
          success: false,
          error: 'Cannot delete your own admin account',
        );
      }

      // Get admin to delete
      final adminUser = await _getAdminById(adminId);
      if (adminUser == null) {
        return AdminDeleteResult(
          success: false,
          error: 'Admin user not found',
        );
      }

      // Delete from local storage
      final usersBox = Hive.box<User>('users');
      await usersBox.delete(adminId);

      // Delete from local auth
      await LocalAuthService.removeLocalUser(adminUser.email);

      // Delete from Firestore
      await _deleteAdminFromFirestore(adminId);

      // Delete Firebase Auth user
      try {
        // Note: This requires the user to be recently authenticated
        await FirebaseService.auth.currentUser?.delete();
      } catch (e) {
        print('[ADMIN_USER] Could not delete Firebase Auth user: $e');
      }

      // Audit log
      await _logAdminAction(
        action: 'DELETE_ADMIN',
        userId: adminId,
        performedBy: deletedByAdminId,
        details: {
          'deletedEmail': adminUser.email,
          'deletedDisplayName': adminUser.displayName,
        },
      );

      return AdminDeleteResult(
        success: true,
        message: 'Admin user deleted successfully',
      );

    } catch (e) {
      return AdminDeleteResult(
        success: false,
        error: 'Failed to delete admin user: ${e.toString()}',
      );
    }
  }

  /// Get all admin users
  static Future<List<User>> getAllAdmins() async {
    try {
      final usersBox = Hive.box<User>('users');
      return usersBox.values.where((user) => user.role == 'admin').toList();
    } catch (e) {
      print('[ADMIN_USER] Failed to get all admins: $e');
      return [];
    }
  }

  /// Get admin by ID
  static Future<User?> getAdminById(String adminId) async {
    return _getAdminById(adminId);
  }

  /// Get admin by email
  static Future<User?> getAdminByEmail(String email) async {
    try {
      final usersBox = Hive.box<User>('users');
      return usersBox.values.firstWhere(
        (user) => user.role == 'admin' && user.email == email,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if user is admin
  static Future<bool> isUserAdmin(String userId) async {
    final admin = await _getAdminById(userId);
    return admin != null;
  }

  /// Get admin statistics
  static Future<Map<String, dynamic>> getAdminStatistics() async {
    try {
      final allAdmins = await getAllAdmins();
      final activeAdmins = allAdmins.where((admin) => admin.isActive).length;
      final inactiveAdmins = allAdmins.where((admin) => !admin.isActive).length;

      return {
        'totalAdmins': allAdmins.length,
        'activeAdmins': activeAdmins,
        'inactiveAdmins': inactiveAdmins,
        'admins': allAdmins.map((admin) => {
          'id': admin.id,
          'email': admin.email,
          'displayName': admin.displayName,
          'isActive': admin.isActive,
          'createdAt': admin.createdAt.toIso8601String(),
          'lastLoginAt': admin.lastLoginAt.toIso8601String(),
        }).toList(),
      };

    } catch (e) {
      return {
        'error': e.toString(),
        'totalAdmins': 0,
        'activeAdmins': 0,
        'inactiveAdmins': 0,
        'admins': [],
      };
    }
  }

  /// Validate admin creation input
  static Future<ValidationResult> _validateAdminCreationInput({
    required String email,
    required String password,
    required String displayName,
    required String schoolName,
  }) async {
    // Email validation
    if (email.isEmpty) {
      return ValidationResult(isValid: false, errorMessage: 'Email is required');
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return ValidationResult(isValid: false, errorMessage: 'Invalid email format');
    }

    // Password validation
    if (password.length < 8) {
      return ValidationResult(isValid: false, errorMessage: 'Password must be at least 8 characters');
    }

    if (!RegExp(r'(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(password)) {
      return ValidationResult(
        isValid: false,
        errorMessage: 'Password must contain at least one uppercase letter, one lowercase letter, and one number',
      );
    }

    // Display name validation
    if (displayName.isEmpty) {
      return ValidationResult(isValid: false, errorMessage: 'Display name is required');
    }

    if (displayName.length < 2) {
      return ValidationResult(isValid: false, errorMessage: 'Display name must be at least 2 characters');
    }

    // School name validation
    if (schoolName.isEmpty) {
      return ValidationResult(isValid: false, errorMessage: 'School name is required');
    }

    return ValidationResult(isValid: true);
  }

  /// Get admin by ID (internal)
  static Future<User?> _getAdminById(String adminId) async {
    try {
      final usersBox = Hive.box<User>('users');
      final user = usersBox.get(adminId);
      return user?.role == 'admin' ? user : null;
    } catch (e) {
      return null;
    }
  }

  /// Get user by email (internal)
  static Future<User?> _getUserByEmail(String email) async {
    try {
      final usersBox = Hive.box<User>('users');
      return usersBox.values.firstWhere((user) => user.email == email);
    } catch (e) {
      return null;
    }
  }

  /// Save admin to Firestore
  static Future<void> _saveAdminToFirestore(User adminUser) async {
    try {
      await FirebaseService.firestore.collection('users').doc(adminUser.id).set({
        'email': adminUser.email,
        'displayName': adminUser.displayName,
        'role': adminUser.role,
        'createdAt': Timestamp.fromDate(adminUser.createdAt),
        'lastLoginAt': Timestamp.fromDate(adminUser.lastLoginAt ?? DateTime.now()),
        'isActive': adminUser.isActive,
        'schoolName': adminUser.schoolName,
        'schoolAddress': adminUser.schoolAddress,
        'schoolPhone': adminUser.schoolPhone,
        'adminTitle': adminUser.adminTitle,
        'createdBy': adminUser.createdBy,
        'deviceId': await _getDeviceId(),
        'lastDeviceSync': Timestamp.fromDate(DateTime.now()),
        'adminPrivileges': {
          'canCreateUsers': true,
          'canDeleteUsers': true,
          'canManageSystem': true,
          'canViewAllData': true,
        },
      });
    } catch (e) {
      print('[ADMIN_USER] Failed to save admin to Firestore: $e');
    }
  }

  /// Update admin in Firestore
  static Future<void> _updateAdminInFirestore(User adminUser) async {
    try {
      await FirebaseService.firestore.collection('users').doc(adminUser.id).update({
        'displayName': adminUser.displayName,
        'lastLoginAt': Timestamp.fromDate(adminUser.lastLoginAt ?? DateTime.now()),
        'isActive': adminUser.isActive,
        'schoolAddress': adminUser.schoolAddress,
        'schoolPhone': adminUser.schoolPhone,
        'adminTitle': adminUser.adminTitle,
        'lastUpdated': Timestamp.fromDate(adminUser.lastUpdated ?? DateTime.now()),
        'updatedBy': adminUser.updatedBy,
        'lastDeviceSync': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('[ADMIN_USER] Failed to update admin in Firestore: $e');
    }
  }

  /// Delete admin from Firestore
  static Future<void> _deleteAdminFromFirestore(String adminId) async {
    try {
      await FirebaseService.firestore.collection('users').doc(adminId).delete();
    } catch (e) {
      print('[ADMIN_USER] Failed to delete admin from Firestore: $e');
    }
  }

  /// Create admin settings
  static Future<void> _createAdminSettings(String adminId, String schoolName) async {
    try {
      final settingsBox = await Hive.openBox(_adminSettingsBoxName);
      await settingsBox.put('${adminId}_settings', {
        'schoolName': schoolName,
        'adminId': adminId,
        'createdAt': DateTime.now().toIso8601String(),
        'preferences': {
          'theme': 'system',
          'language': 'en',
          'notifications': true,
          'autoBackup': true,
        },
        'permissions': {
          'canCreateUsers': true,
          'canDeleteUsers': true,
          'canManageSystem': true,
          'canViewAllData': true,
        },
      });
    } catch (e) {
      print('[ADMIN_USER] Failed to create admin settings: $e');
    }
  }

  /// Log admin action
  static Future<void> _logAdminAction({
    required String action,
    required String userId,
    String? performedBy,
    Map<String, dynamic>? details,
  }) async {
    try {
      final auditBox = await Hive.openBox(_adminAuditBoxName);
      final auditEntry = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'action': action,
        'userId': userId,
        'performedBy': performedBy,
        'timestamp': DateTime.now().toIso8601String(),
        'details': details,
        'deviceId': await _getDeviceId(),
      };

      await auditBox.add(auditEntry);

      // Also log to main auth event logger
      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.adminAction,
        'Admin action: $action for user $userId',
        userId: userId,
      );

    } catch (e) {
      print('[ADMIN_USER] Failed to log admin action: $e');
    }
  }

  /// Get admin audit log
  static Future<List<Map<String, dynamic>>> getAdminAuditLog({
    String? adminId,
    int limit = 100,
  }) async {
    try {
      final auditBox = await Hive.openBox(_adminAuditBoxName);
      final allEntries = auditBox.values.cast<Map<String, dynamic>>();

      var filteredEntries = allEntries;

      if (adminId != null) {
        filteredEntries = allEntries.where((entry) =>
          entry['userId'] == adminId || entry['performedBy'] == adminId
        );
      }

      return filteredEntries
          .toList()
          .reversed
          .take(limit)
          .toList();

    } catch (e) {
      print('[ADMIN_USER] Failed to get admin audit log: $e');
      return [];
    }
  }

  /// Get device ID
  static Future<String> _getDeviceId() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'device_${timestamp.substring(timestamp.length - 8)}';
  }

  /// Check if admin session is valid
  static bool isAdminSessionValid() {
    final currentUser = user_role.AccessControlManager.getCurrentUser();
    if (currentUser == null || currentUser.role != user_role.UserRole.admin) {
      return false;
    }

    // Check session timeout
    final lastLogin = currentUser.lastLoginAt;
    if (lastLogin == null) return false;

    final timeSinceLogin = DateTime.now().difference(lastLogin);
    return timeSinceLogin < _adminSessionTimeout;
  }

  /// Get admin dashboard data
  static Future<Map<String, dynamic>> getAdminDashboardData() async {
    try {
      final stats = await getAdminStatistics();
      final currentUser = user_role.AccessControlManager.getCurrentUser();

      return {
        'currentAdmin': currentUser != null ? {
          'id': currentUser.id,
          'email': currentUser.email,
          'displayName': currentUser.displayName,
          'adminTitle': currentUser.adminTitle,
          'lastLoginAt': currentUser.lastLoginAt?.toIso8601String(),
        } : null,
        'adminStats': stats,
        'sessionValid': isAdminSessionValid(),
        'recentAuditLog': await getAdminAuditLog(limit: 10),
      };

    } catch (e) {
      return {
        'error': e.toString(),
        'currentAdmin': null,
        'adminStats': {},
        'sessionValid': false,
        'recentAuditLog': [],
      };
    }
  }
}

/// Validation Result
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}

/// Admin Creation Result
class AdminCreationResult {
  final bool success;
  final User? user;
  final String? message;
  final String? error;

  AdminCreationResult({
    required this.success,
    this.user,
    this.message,
    this.error,
  });
}

/// Admin Update Result
class AdminUpdateResult {
  final bool success;
  final User? user;
  final String? message;
  final String? error;

  AdminUpdateResult({
    required this.success,
    this.user,
    this.message,
    this.error,
  });
}

/// Admin Delete Result
class AdminDeleteResult {
  final bool success;
  final String? message;
  final String? error;

  AdminDeleteResult({
    required this.success,
    this.message,
    this.error,
  });
}