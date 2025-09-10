import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:crypto/crypto.dart';
import 'encryption_service.dart';
import 'comprehensive_auth_service.dart';

/// Multi-Factor Authentication Service
class MFAService {
  static const String _mfaBoxName = 'mfa_data';
  static const int _totpTimeStep = 30;
  static const int _backupCodesCount = 10;

  static bool _isInitialized = false;

  /// Initialize MFA service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.openBox(_mfaBoxName);
      _isInitialized = true;
      print('[MFA] Multi-factor authentication service initialized');
    } catch (e) {
      print('[MFA] Failed to initialize MFA service: $e');
      rethrow;
    }
  }

  /// Enable MFA for user
  static Future<MFAEnableResult> enableMFA(String userId, MFAFactor factor) async {
    try {
      final mfaBox = await Hive.openBox(_mfaBoxName);
      final userMFAKey = 'user_$userId';

      // Get existing MFA settings
      final existingSettings = mfaBox.get(userMFAKey) as Map<String, dynamic>? ?? {};

      // Generate secret for TOTP
      final secret = _generateTOTPSecret();

      // Update MFA settings
      final mfaSettings = {
        'enabled': true,
        'factors': [...(existingSettings['factors'] as List? ?? []), factor.toString()],
        'totpSecret': factor == MFAFactor.totp ? secret : existingSettings['totpSecret'],
        'backupCodes': factor == MFAFactor.backupCodes ? _generateBackupCodes() : existingSettings['backupCodes'],
        'enabledAt': DateTime.now().toIso8601String(),
        'lastVerified': null,
      };

      // Encrypt sensitive data
      final encryptedSettings = EncryptionService.encryptUserData(mfaSettings);

      await mfaBox.put(userMFAKey, encryptedSettings);

      // Log MFA enable event
      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.mfaEnabled,
        'MFA enabled for user with factor: $factor',
        userId: userId,
      );

      print('[MFA] MFA enabled for user $userId with factor $factor');

      return MFAEnableResult(
        success: true,
        secret: factor == MFAFactor.totp ? secret : null,
        backupCodes: factor == MFAFactor.backupCodes ? mfaSettings['backupCodes'] : null,
      );

    } catch (e) {
      print('[MFA] Failed to enable MFA: $e');

      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.error,
        'Failed to enable MFA: $e',
        userId: userId,
      );

      return MFAEnableResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Disable MFA for user
  static Future<bool> disableMFA(String userId) async {
    try {
      final mfaBox = await Hive.openBox(_mfaBoxName);
      final userMFAKey = 'user_$userId';

      await mfaBox.delete(userMFAKey);

      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.mfaDisabled,
        'MFA disabled for user',
        userId: userId,
      );

      print('[MFA] MFA disabled for user $userId');
      return true;

    } catch (e) {
      print('[MFA] Failed to disable MFA: $e');

      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.error,
        'Failed to disable MFA: $e',
        userId: userId,
      );

      return false;
    }
  }

  /// Verify MFA code
  static Future<MFAVerifyResult> verifyMFACode(String userId, String code, MFAFactor factor) async {
    try {
      final mfaBox = await Hive.openBox(_mfaBoxName);
      final userMFAKey = 'user_$userId';

      final encryptedSettings = mfaBox.get(userMFAKey) as String?;
      if (encryptedSettings == null) {
        return MFAVerifyResult(
          success: false,
          error: 'MFA not enabled for user',
        );
      }

      final mfaSettings = EncryptionService.decryptUserData(encryptedSettings);

      if (!(mfaSettings['enabled'] as bool? ?? false)) {
        return MFAVerifyResult(
          success: false,
          error: 'MFA not enabled for user',
        );
      }

      final factors = (mfaSettings['factors'] as List?)?.map((f) => f.toString()).toList() ?? [];
      if (!factors.contains(factor.toString())) {
        return MFAVerifyResult(
          success: false,
          error: 'MFA factor not enabled',
        );
      }

      bool codeValid = false;

      switch (factor) {
        case MFAFactor.totp:
          final secret = mfaSettings['totpSecret'] as String?;
          if (secret != null) {
            codeValid = _verifyTOTPCode(secret, code);
          }
          break;

        case MFAFactor.backupCodes:
          final backupCodes = mfaSettings['backupCodes'] as List?;
          if (backupCodes != null && backupCodes.contains(code)) {
            // Remove used backup code
            backupCodes.remove(code);
            mfaSettings['backupCodes'] = backupCodes;
            final updatedEncrypted = EncryptionService.encryptUserData(mfaSettings);
            await mfaBox.put(userMFAKey, updatedEncrypted);
            codeValid = true;
          }
          break;

        case MFAFactor.sms:
          // SMS verification would be handled by Firebase Auth
          codeValid = await _verifySMSCode(userId, code);
          break;

        case MFAFactor.email:
          // Email verification would be handled by Firebase Auth
          codeValid = await _verifyEmailCode(userId, code);
          break;
      }

      if (codeValid) {
        // Update last verified timestamp
        mfaSettings['lastVerified'] = DateTime.now().toIso8601String();
        final updatedEncrypted = EncryptionService.encryptUserData(mfaSettings);
        await mfaBox.put(userMFAKey, updatedEncrypted);

        ComprehensiveAuthService.logAuthEvent(
          AuthEventType.mfaVerified,
          'MFA verification successful with factor: $factor',
          userId: userId,
        );

        return MFAVerifyResult(success: true);
      } else {
        ComprehensiveAuthService.logAuthEvent(
          AuthEventType.mfaVerificationFailed,
          'MFA verification failed with factor: $factor',
          userId: userId,
        );

        return MFAVerifyResult(
          success: false,
          error: 'Invalid MFA code',
        );
      }

    } catch (e) {
      print('[MFA] Failed to verify MFA code: $e');

      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.error,
        'MFA verification error: $e',
        userId: userId,
      );

      return MFAVerifyResult(
        success: false,
        error: 'Verification failed: ${e.toString()}',
      );
    }
  }

  /// Check if MFA is enabled for user
  static Future<bool> isMFAEnabled(String userId) async {
    try {
      final mfaBox = await Hive.openBox(_mfaBoxName);
      final userMFAKey = 'user_$userId';

      final encryptedSettings = mfaBox.get(userMFAKey) as String?;
      if (encryptedSettings == null) return false;

      final mfaSettings = EncryptionService.decryptUserData(encryptedSettings);
      return mfaSettings['enabled'] as bool? ?? false;

    } catch (e) {
      print('[MFA] Failed to check MFA status: $e');
      return false;
    }
  }

  /// Get MFA settings for user
  static Future<Map<String, dynamic>?> getMFASettings(String userId) async {
    try {
      final mfaBox = await Hive.openBox(_mfaBoxName);
      final userMFAKey = 'user_$userId';

      final encryptedSettings = mfaBox.get(userMFAKey) as String?;
      if (encryptedSettings == null) return null;

      final mfaSettings = EncryptionService.decryptUserData(encryptedSettings);

      // Don't return sensitive data like secrets
      return {
        'enabled': mfaSettings['enabled'],
        'factors': mfaSettings['factors'],
        'enabledAt': mfaSettings['enabledAt'],
        'lastVerified': mfaSettings['lastVerified'],
        'backupCodesCount': (mfaSettings['backupCodes'] as List?)?.length ?? 0,
      };

    } catch (e) {
      print('[MFA] Failed to get MFA settings: $e');
      return null;
    }
  }

  /// Generate TOTP secret
  static String _generateTOTPSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64.encode(bytes);
  }

  /// Verify TOTP code
  static bool _verifyTOTPCode(String secret, String code) {
    try {
      final secretBytes = base64.decode(secret);
      final timeStep = DateTime.now().millisecondsSinceEpoch ~/ 1000 ~/ _totpTimeStep;

      // Check current time step and adjacent steps for clock skew tolerance
      for (int i = -1; i <= 1; i++) {
        final timeStepBytes = _intToBytes(timeStep + i);
        final hmac = Hmac(sha1, secretBytes);
        final hash = hmac.convert(timeStepBytes);

        final offset = hash.bytes[hash.bytes.length - 1] & 0xf;
        final binary = ((hash.bytes[offset] & 0x7f) << 24) |
                      ((hash.bytes[offset + 1] & 0xff) << 16) |
                      ((hash.bytes[offset + 2] & 0xff) << 8) |
                      (hash.bytes[offset + 3] & 0xff);

        final totpCode = (binary % 1000000).toString().padLeft(6, '0');

        if (totpCode == code) {
          return true;
        }
      }

      return false;

    } catch (e) {
      print('[MFA] TOTP verification error: $e');
      return false;
    }
  }

  /// Generate backup codes
  static List<String> _generateBackupCodes() {
    final codes = <String>[];
    final random = Random.secure();

    for (int i = 0; i < _backupCodesCount; i++) {
      final code = List.generate(8, (index) => random.nextInt(10)).join();
      codes.add(code);
    }

    return codes;
  }

  /// Verify SMS code (placeholder for Firebase Auth integration)
  static Future<bool> _verifySMSCode(String userId, String code) async {
    // This would integrate with Firebase Auth phone verification
    // For now, return false as placeholder
    print('[MFA] SMS verification not implemented yet');
    return false;
  }

  /// Verify email code (placeholder for Firebase Auth integration)
  static Future<bool> _verifyEmailCode(String userId, String code) async {
    // This would integrate with Firebase Auth email verification
    // For now, return false as placeholder
    print('[MFA] Email verification not implemented yet');
    return false;
  }

  /// Convert int to bytes for TOTP
  static List<int> _intToBytes(int value) {
    final bytes = <int>[];
    for (int i = 7; i >= 0; i--) {
      bytes.add((value >> (i * 8)) & 0xff);
    }
    return bytes;
  }

  /// Regenerate backup codes
  static Future<List<String>?> regenerateBackupCodes(String userId) async {
    try {
      final mfaBox = await Hive.openBox(_mfaBoxName);
      final userMFAKey = 'user_$userId';

      final encryptedSettings = mfaBox.get(userMFAKey) as String?;
      if (encryptedSettings == null) return null;

      final mfaSettings = EncryptionService.decryptUserData(encryptedSettings);

      final newBackupCodes = _generateBackupCodes();
      mfaSettings['backupCodes'] = newBackupCodes;

      final updatedEncrypted = EncryptionService.encryptUserData(mfaSettings);
      await mfaBox.put(userMFAKey, updatedEncrypted);

      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.mfaBackupCodesRegenerated,
        'Backup codes regenerated for user',
        userId: userId,
      );

      return newBackupCodes;

    } catch (e) {
      print('[MFA] Failed to regenerate backup codes: $e');

      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.error,
        'Failed to regenerate backup codes: $e',
        userId: userId,
      );

      return null;
    }
  }

  /// Get MFA status summary
  static Future<Map<String, dynamic>> getMFAStatus(String userId) async {
    final isEnabled = await isMFAEnabled(userId);
    final settings = await getMFASettings(userId);

    return {
      'enabled': isEnabled,
      'settings': settings,
      'factors': settings?['factors'] ?? [],
      'lastVerified': settings?['lastVerified'],
      'backupCodesRemaining': settings?['backupCodesCount'] ?? 0,
    };
  }
}

/// MFA Factors
enum MFAFactor {
  totp,        // Time-based One-Time Password (Authenticator apps)
  sms,         // SMS verification
  email,       // Email verification
  backupCodes, // Backup recovery codes
}

/// MFA Enable Result
class MFAEnableResult {
  final bool success;
  final String? secret;
  final List<String>? backupCodes;
  final String? error;

  MFAEnableResult({
    required this.success,
    this.secret,
    this.backupCodes,
    this.error,
  });
}

/// MFA Verify Result
class MFAVerifyResult {
  final bool success;
  final String? error;

  MFAVerifyResult({
    required this.success,
    this.error,
  });
}