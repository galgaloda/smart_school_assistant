import 'dart:math';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';
import '../models/user_role.dart' as user_role;
import 'firebase_service.dart';
import 'local_auth_service.dart';
import 'auth_event_logger.dart';

/// User Creation Service
/// Handles comprehensive user creation with password generation for all user types
class UserCreationService {
  static const String _generatedPasswordsBoxName = 'generated_passwords';

  static bool _isInitialized = false;

  /// Initialize the user creation service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.openBox(_generatedPasswordsBoxName);
      _isInitialized = true;
      print('[USER_CREATION] User creation service initialized');
    } catch (e) {
      print('[USER_CREATION] Failed to initialize user creation service: $e');
      rethrow;
    }
  }

  /// Generate a secure random password
  static String generateSecurePassword({
    int length = 12,
    bool includeUppercase = true,
    bool includeLowercase = true,
    bool includeNumbers = true,
    bool includeSpecialChars = true,
  }) {
    const String uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const String numbers = '0123456789';
    const String specialChars = '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    String chars = '';
    if (includeLowercase) chars += lowercase;
    if (includeUppercase) chars += uppercase;
    if (includeNumbers) chars += numbers;
    if (includeSpecialChars) chars += specialChars;

    if (chars.isEmpty) chars = lowercase; // Fallback

    final Random random = Random.secure();
    String password = '';

    // Ensure at least one character from each required type
    if (includeUppercase && uppercase.isNotEmpty) {
      password += uppercase[random.nextInt(uppercase.length)];
    }
    if (includeLowercase && lowercase.isNotEmpty) {
      password += lowercase[random.nextInt(lowercase.length)];
    }
    if (includeNumbers && numbers.isNotEmpty) {
      password += numbers[random.nextInt(numbers.length)];
    }
    if (includeSpecialChars && specialChars.isNotEmpty) {
      password += specialChars[random.nextInt(specialChars.length)];
    }

    // Fill the rest randomly
    while (password.length < length) {
      password += chars[random.nextInt(chars.length)];
    }

    // Shuffle the password for better randomness
    List<String> passwordChars = password.split('');
    passwordChars.shuffle(random);
    return passwordChars.join();
  }

  /// Create a new user with generated password
  static Future<UserCreationResult> createUser({
    required String email,
    required String displayName,
    required String role,
    required String createdByAdminId,
    String? schoolName,
    String? schoolAddress,
    String? schoolPhone,
    bool autoGeneratePassword = true,
    String? customPassword,
  }) async {
    try {
      // Verify permissions
      final currentUser = user_role.AccessControlManager.getCurrentUser();
      if (currentUser == null || !currentUser.hasPermission(user_role.Permission.createUsers)) {
        return UserCreationResult(
          success: false,
          error: 'Insufficient permissions to create users',
        );
      }

      // Validate input
      final validation = await _validateUserCreationInput(
        email: email,
        displayName: displayName,
        role: role,
      );

      if (!validation.isValid) {
        return UserCreationResult(
          success: false,
          error: validation.errorMessage,
        );
      }

      // Check if email already exists
      final existingUser = await _getUserByEmail(email);
      if (existingUser != null) {
        return UserCreationResult(
          success: false,
          error: 'User with this email already exists',
        );
      }

      // Generate or use custom password
      final password = autoGeneratePassword
          ? generateSecurePassword()
          : customPassword ?? generateSecurePassword();

      if (!autoGeneratePassword && (customPassword == null || customPassword.isEmpty)) {
        return UserCreationResult(
          success: false,
          error: 'Password is required when not auto-generating',
        );
      }

      String userId;

      if (_isFirebaseEnabledPlatform()) {
        // Create Firebase user for supported platforms
        final userCredential = await FirebaseService.auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Update display name
        await userCredential.user?.updateDisplayName(displayName);
        userId = userCredential.user!.uid;
      } else {
        // Generate local user ID for non-Firebase platforms
        final random = Random();
        userId = 'user_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}';
      }

      // Create user object
      final newUser = User(
        id: userId,
        email: email,
        displayName: displayName,
        role: role,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
        schoolName: schoolName,
        schoolAddress: schoolAddress,
        schoolPhone: schoolPhone,
      );

      // Save to local storage
      final usersBox = Hive.box<User>('users');
      await usersBox.put(userId, newUser);

      // Register for local authentication
      await LocalAuthService.registerLocalUser(email, password, newUser);

      // Save to Firestore if Firebase is available
      if (_isFirebaseEnabledPlatform()) {
        await _saveUserToFirestore(newUser);
      }

      // Store generated password for admin reference
      if (autoGeneratePassword) {
        await _storeGeneratedPassword(userId, password);
      }

      // Log user creation
      await AuthEventLogger.logEvent(
        AuthEventType.registrationSuccessful,
        'User created: $email by admin ${currentUser.email}',
        userId: userId,
        severity: AuthEventSeverity.info,
      );

      return UserCreationResult(
        success: true,
        user: newUser,
        generatedPassword: autoGeneratePassword ? password : null,
        message: 'User created successfully',
      );

    } catch (e) {
      await AuthEventLogger.logEvent(
        AuthEventType.registrationFailed,
        'Failed to create user: $e',
        severity: AuthEventSeverity.error,
      );

      return UserCreationResult(
        success: false,
        error: 'Failed to create user: ${e.toString()}',
      );
    }
  }

  /// Get stored generated password for a user
  static Future<String?> getGeneratedPassword(String userId) async {
    try {
      final passwordsBox = Hive.box(_generatedPasswordsBoxName);
      return passwordsBox.get(userId) as String?;
    } catch (e) {
      print('[USER_CREATION] Failed to get generated password: $e');
      return null;
    }
  }

  /// Reset user password with new generated password
  static Future<PasswordResetResult> resetUserPassword({
    required String userId,
    required String resetByAdminId,
  }) async {
    try {
      // Verify permissions
      final currentUser = user_role.AccessControlManager.getCurrentUser();
      if (currentUser == null || !currentUser.hasPermission(user_role.Permission.editUsers)) {
        return PasswordResetResult(
          success: false,
          error: 'Insufficient permissions to reset passwords',
        );
      }

      // Get user
      final usersBox = Hive.box<User>('users');
      final user = usersBox.get(userId);
      if (user == null) {
        return PasswordResetResult(
          success: false,
          error: 'User not found',
        );
      }

      // Generate new password
      final newPassword = generateSecurePassword();

      // Update local authentication
      await LocalAuthService.registerLocalUser(user.email, newPassword, user);

      // Store new generated password
      await _storeGeneratedPassword(userId, newPassword);

      // Log password reset
      await AuthEventLogger.logEvent(
        AuthEventType.securityEvent,
        'Password reset for user ${user.email} by admin ${currentUser.email}',
        userId: userId,
        severity: AuthEventSeverity.warning,
      );

      return PasswordResetResult(
        success: true,
        newPassword: newPassword,
        message: 'Password reset successfully',
      );

    } catch (e) {
      return PasswordResetResult(
        success: false,
        error: 'Failed to reset password: ${e.toString()}',
      );
    }
  }

  /// Check if platform supports Firebase
  static bool _isFirebaseEnabledPlatform() {
    if (kIsWeb) return true;
    if (!Platform.isWindows && !Platform.isLinux) return true;
    return false;
  }

  /// Validate user creation input
  static Future<ValidationResult> _validateUserCreationInput({
    required String email,
    required String displayName,
    required String role,
  }) async {
    // Email validation
    if (email.isEmpty) {
      return ValidationResult(isValid: false, errorMessage: 'Email is required');
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return ValidationResult(isValid: false, errorMessage: 'Invalid email format');
    }

    // Display name validation
    if (displayName.isEmpty) {
      return ValidationResult(isValid: false, errorMessage: 'Display name is required');
    }

    if (displayName.length < 2) {
      return ValidationResult(isValid: false, errorMessage: 'Display name must be at least 2 characters');
    }

    // Role validation
    final validRoles = ['admin', 'teacher', 'student', 'staff', 'parent', 'principal'];
    if (!validRoles.contains(role)) {
      return ValidationResult(isValid: false, errorMessage: 'Invalid role specified');
    }

    return ValidationResult(isValid: true);
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

  /// Store generated password
  static Future<void> _storeGeneratedPassword(String userId, String password) async {
    try {
      final passwordsBox = Hive.box(_generatedPasswordsBoxName);
      await passwordsBox.put(userId, password);
    } catch (e) {
      print('[USER_CREATION] Failed to store generated password: $e');
    }
  }

  /// Save user to Firestore
  static Future<void> _saveUserToFirestore(User user) async {
    try {
      await FirebaseService.firestore.collection('users').doc(user.id).set({
        'email': user.email,
        'displayName': user.displayName,
        'role': user.role,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'lastLoginAt': Timestamp.fromDate(user.lastLoginAt ?? DateTime.now()),
        'isActive': user.isActive,
        'schoolName': user.schoolName,
        'schoolAddress': user.schoolAddress,
        'schoolPhone': user.schoolPhone,
        'deviceId': await _getDeviceId(),
        'lastDeviceSync': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('[USER_CREATION] Failed to save user to Firestore: $e');
    }
  }

  /// Get device ID
  static Future<String> _getDeviceId() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'device_${timestamp.substring(timestamp.length - 8)}';
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

/// User Creation Result
class UserCreationResult {
  final bool success;
  final User? user;
  final String? generatedPassword;
  final String? message;
  final String? error;

  UserCreationResult({
    required this.success,
    this.user,
    this.generatedPassword,
    this.message,
    this.error,
  });
}

/// Password Reset Result
class PasswordResetResult {
  final bool success;
  final String? newPassword;
  final String? message;
  final String? error;

  PasswordResetResult({
    required this.success,
    this.newPassword,
    this.message,
    this.error,
  });
}