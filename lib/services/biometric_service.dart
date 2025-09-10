import 'dart:async';
import 'package:local_auth/local_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'encryption_service.dart';
import 'session_manager.dart';

/// Biometric authentication service for enhanced security
class BiometricService {
  static const String _biometricBoxName = 'biometric_data';
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _biometricCredentialsKey = 'biometric_credentials';

  static final LocalAuthentication _localAuth = LocalAuthentication();
  static bool _isInitialized = false;

  /// Initialize biometric service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.openBox(_biometricBoxName);
      _isInitialized = true;
      print('[BIOMETRIC] Biometric service initialized');
    } catch (e) {
      print('[BIOMETRIC] Failed to initialize biometric service: $e');
      rethrow;
    }
  }

  /// Check if biometric authentication is available
  static Future<BiometricAvailability> checkBiometricAvailability() async {
    try {
      final canAuthenticateWithBiometrics = await _localAuth.canCheckBiometrics;
      final canAuthenticate = await _localAuth.isDeviceSupported();

      if (!canAuthenticate) {
        return BiometricAvailability(
          available: false,
          reason: 'Device does not support biometric authentication',
        );
      }

      if (!canAuthenticateWithBiometrics) {
        return BiometricAvailability(
          available: false,
          reason: 'Biometric authentication not available',
        );
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (availableBiometrics.isEmpty) {
        return BiometricAvailability(
          available: false,
          reason: 'No biometric methods enrolled',
        );
      }

      return BiometricAvailability(
        available: true,
        biometrics: availableBiometrics,
      );
    } on PlatformException catch (e) {
      print('[BIOMETRIC] Platform exception: $e');
      return BiometricAvailability(
        available: false,
        reason: 'Platform error: ${e.message}',
      );
    } catch (e) {
      print('[BIOMETRIC] Error checking biometric availability: $e');
      return BiometricAvailability(
        available: false,
        reason: 'Unknown error occurred',
      );
    }
  }

  /// Authenticate using biometrics
  static Future<BiometricResult> authenticate({
    String? localizedReason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
  }) async {
    try {
      final availability = await checkBiometricAvailability();
      if (!availability.available) {
        return BiometricResult(
          success: false,
          reason: availability.reason,
        );
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: localizedReason ?? 'Please authenticate to access your account',
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        await SessionManager.updateActivity();
        return BiometricResult(
          success: true,
          reason: 'Authentication successful',
        );
      } else {
        return BiometricResult(
          success: false,
          reason: 'Authentication failed or cancelled',
        );
      }
    } on PlatformException catch (e) {
      print('[BIOMETRIC] Platform exception during authentication: $e');

      String reason;
      switch (e.code) {
        case 'NotAvailable':
          reason = 'Biometric authentication not available';
          break;
        case 'NotEnrolled':
          reason = 'No biometrics enrolled on this device';
          break;
        case 'LockedOut':
          reason = 'Too many failed attempts. Try again later';
          break;
        case 'PermanentlyLockedOut':
          reason = 'Biometric authentication permanently locked out';
          break;
        default:
          reason = 'Authentication error: ${e.message}';
      }

      return BiometricResult(
        success: false,
        reason: reason,
      );
    } catch (e) {
      print('[BIOMETRIC] Error during biometric authentication: $e');
      return BiometricResult(
        success: false,
        reason: 'Unknown authentication error',
      );
    }
  }

  /// Enable biometric authentication for current user
  static Future<BiometricSetupResult> enableBiometricAuth({
    required String email,
    required String password,
  }) async {
    try {
      // First verify credentials
      final availability = await checkBiometricAvailability();
      if (!availability.available) {
        return BiometricSetupResult(
          success: false,
          reason: availability.reason,
        );
      }

      // Authenticate with biometrics to confirm setup
      final authResult = await authenticate(
        localizedReason: 'Authenticate to enable biometric login',
      );

      if (!authResult.success) {
        return BiometricSetupResult(
          success: false,
          reason: authResult.reason,
        );
      }

      // Store biometric credentials securely
      final biometricData = {
        'email': email,
        'password': password,
        'enabledAt': DateTime.now().toIso8601String(),
        'deviceId': await _getDeviceId(),
      };

      final encryptedData = EncryptionService.encryptUserData(biometricData);

      final biometricBox = await Hive.openBox(_biometricBoxName);
      await biometricBox.put(_biometricCredentialsKey, encryptedData);
      await biometricBox.put(_biometricEnabledKey, true);

      await SessionManager.setBiometricEnabled(true);

      print('[BIOMETRIC] Biometric authentication enabled for user: $email');
      return BiometricSetupResult(
        success: true,
        reason: 'Biometric authentication enabled successfully',
      );
    } catch (e) {
      print('[BIOMETRIC] Failed to enable biometric auth: $e');
      return BiometricSetupResult(
        success: false,
        reason: 'Failed to enable biometric authentication',
      );
    }
  }

  /// Disable biometric authentication
  static Future<bool> disableBiometricAuth() async {
    try {
      final biometricBox = await Hive.openBox(_biometricBoxName);
      await biometricBox.delete(_biometricCredentialsKey);
      await biometricBox.put(_biometricEnabledKey, false);

      await SessionManager.setBiometricEnabled(false);

      print('[BIOMETRIC] Biometric authentication disabled');
      return true;
    } catch (e) {
      print('[BIOMETRIC] Failed to disable biometric auth: $e');
      return false;
    }
  }

  /// Check if biometric authentication is enabled
  static Future<bool> isBiometricEnabled() async {
    try {
      final biometricBox = await Hive.openBox(_biometricBoxName);
      return biometricBox.get(_biometricEnabledKey, defaultValue: false);
    } catch (e) {
      print('[BIOMETRIC] Failed to check biometric status: $e');
      return false;
    }
  }

  /// Attempt biometric login
  static Future<BiometricLoginResult> biometricLogin() async {
    try {
      if (!await isBiometricEnabled()) {
        return BiometricLoginResult(
          success: false,
          reason: 'Biometric authentication not enabled',
        );
      }

      // Authenticate with biometrics
      final authResult = await authenticate(
        localizedReason: 'Authenticate to login',
      );

      if (!authResult.success) {
        return BiometricLoginResult(
          success: false,
          reason: authResult.reason,
        );
      }

      // Retrieve stored credentials
      final biometricBox = await Hive.openBox(_biometricBoxName);
      final encryptedData = biometricBox.get(_biometricCredentialsKey) as String?;

      if (encryptedData == null) {
        return BiometricLoginResult(
          success: false,
          reason: 'Biometric credentials not found',
        );
      }

      final biometricData = EncryptionService.decryptUserData(encryptedData);
      final email = biometricData['email'] as String;
      final password = biometricData['password'] as String;

      print('[BIOMETRIC] Biometric login successful for user: $email');
      return BiometricLoginResult(
        success: true,
        email: email,
        password: password,
        reason: 'Biometric authentication successful',
      );
    } catch (e) {
      print('[BIOMETRIC] Biometric login failed: $e');
      return BiometricLoginResult(
        success: false,
        reason: 'Biometric login failed',
      );
    }
  }

  /// Get device ID for biometric data association
  static Future<String> _getDeviceId() async {
    try {
      // This would typically use device_info_plus
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      return 'device_${timestamp.substring(timestamp.length - 8)}';
    } catch (e) {
      return 'unknown_device';
    }
  }

  /// Get biometric status information
  static Future<Map<String, dynamic>> getBiometricStatus() async {
    final availability = await checkBiometricAvailability();

    return {
      'available': availability.available,
      'enabled': await isBiometricEnabled(),
      'biometrics': availability.biometrics?.map((b) => b.toString()).toList() ?? [],
      'reason': availability.reason,
    };
  }

  /// Reset biometric data (for security)
  static Future<void> resetBiometricData() async {
    try {
      final biometricBox = await Hive.openBox(_biometricBoxName);
      await biometricBox.clear();
      print('[BIOMETRIC] Biometric data reset');
    } catch (e) {
      print('[BIOMETRIC] Failed to reset biometric data: $e');
    }
  }

  /// Handle biometric authentication errors
  static String getBiometricErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'NotAvailable':
        return 'Biometric authentication is not available on this device';
      case 'NotEnrolled':
        return 'No biometric data is enrolled. Please set up biometrics in your device settings';
      case 'LockedOut':
        return 'Too many failed attempts. Please try again later or use password login';
      case 'PermanentlyLockedOut':
        return 'Biometric authentication is permanently locked. Please use password login';
      case 'PasscodeNotSet':
        return 'Device passcode is not set. Please set up a device passcode first';
      default:
        return 'Biometric authentication failed. Please try again or use password login';
    }
  }
}

/// Result of biometric availability check
class BiometricAvailability {
  final bool available;
  final List<BiometricType>? biometrics;
  final String? reason;

  BiometricAvailability({
    required this.available,
    this.biometrics,
    this.reason,
  });
}

/// Result of biometric authentication
class BiometricResult {
  final bool success;
  final String? reason;

  BiometricResult({
    required this.success,
    this.reason,
  });
}

/// Result of biometric setup
class BiometricSetupResult {
  final bool success;
  final String? reason;

  BiometricSetupResult({
    required this.success,
    this.reason,
  });
}

/// Result of biometric login
class BiometricLoginResult {
  final bool success;
  final String? email;
  final String? password;
  final String? reason;

  BiometricLoginResult({
    required this.success,
    this.email,
    this.password,
    this.reason,
  });
}