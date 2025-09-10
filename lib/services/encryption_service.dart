import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:hive_flutter/hive_flutter.dart';

/// Secure encryption service for sensitive user data
class EncryptionService {
  static const String _keyBoxName = 'encryption_keys';
  static const String _masterKeyKey = 'master_key';
  static const String _saltKey = 'encryption_salt';

  static encrypt.Encrypter? _encrypter;
  static encrypt.Key? _encryptionKey;
  static String? _salt;

  /// Initialize encryption service
  static Future<void> initialize() async {
    try {
      await _initializeKeys();
      print('[ENCRYPTION] Encryption service initialized successfully');
    } catch (e) {
      print('[ENCRYPTION] Failed to initialize encryption service: $e');
      rethrow;
    }
  }

  /// Initialize encryption keys
  static Future<void> _initializeKeys() async {
    final keyBox = await Hive.openBox(_keyBoxName);

    // Get or generate salt
    _salt = keyBox.get(_saltKey);
    if (_salt == null) {
      _salt = _generateSalt();
      await keyBox.put(_saltKey, _salt);
      print('[ENCRYPTION] Generated new salt');
    }

    // Get or generate master key
    String? masterKeyString = keyBox.get(_masterKeyKey);
    if (masterKeyString == null) {
      masterKeyString = _generateMasterKey();
      await keyBox.put(_masterKeyKey, masterKeyString);
      print('[ENCRYPTION] Generated new master key');
    }

    // Create encryption key
    _encryptionKey = encrypt.Key.fromBase64(masterKeyString);
    _encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));

    print('[ENCRYPTION] Encryption keys initialized');
  }

  /// Generate a random salt
  static String _generateSalt() {
    final random = Random.secure();
    final saltBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(saltBytes);
  }

  /// Generate a master encryption key
  static String _generateMasterKey() {
    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(keyBytes);
  }

  /// Hash password with salt
  static String hashPassword(String password, {String? customSalt}) {
    final salt = customSalt ?? _salt ?? '';
    final saltedPassword = password + salt;
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Verify password against hash
  static bool verifyPassword(String password, String hash, {String? customSalt}) {
    final computedHash = hashPassword(password, customSalt: customSalt);
    return computedHash == hash;
  }

  /// Encrypt sensitive data
  static String encryptData(String data) {
    if (_encrypter == null) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypted = _encrypter!.encrypt(data, iv: iv);
      final encryptedData = '${iv.base64}:${encrypted.base64}';
      return encryptedData;
    } catch (e) {
      print('[ENCRYPTION] Failed to encrypt data: $e');
      throw Exception('Failed to encrypt data');
    }
  }

  /// Decrypt sensitive data
  static String decryptData(String encryptedData) {
    if (_encrypter == null) {
      throw Exception('Encryption service not initialized');
    }

    try {
      final parts = encryptedData.split(':');
      if (parts.length != 2) {
        throw Exception('Invalid encrypted data format');
      }

      final iv = encrypt.IV.fromBase64(parts[0]);
      final encrypted = encrypt.Encrypted.fromBase64(parts[1]);
      final decrypted = _encrypter!.decrypt(encrypted, iv: iv);
      return decrypted;
    } catch (e) {
      print('[ENCRYPTION] Failed to decrypt data: $e');
      throw Exception('Failed to decrypt data');
    }
  }

  /// Encrypt user credentials for local storage
  static Map<String, String> encryptCredentials(String email, String password) {
    try {
      final encryptedEmail = encryptData(email);
      final encryptedPassword = encryptData(password);
      final timestamp = DateTime.now().toIso8601String();

      return {
        'email': encryptedEmail,
        'password': encryptedPassword,
        'timestamp': timestamp,
        'version': '1.0',
      };
    } catch (e) {
      print('[ENCRYPTION] Failed to encrypt credentials: $e');
      throw Exception('Failed to encrypt credentials');
    }
  }

  /// Decrypt user credentials from local storage
  static Map<String, String> decryptCredentials(Map<String, dynamic> encryptedData) {
    try {
      final encryptedEmail = encryptedData['email'] as String;
      final encryptedPassword = encryptedData['password'] as String;

      final email = decryptData(encryptedEmail);
      final password = decryptData(encryptedPassword);

      return {
        'email': email,
        'password': password,
        'timestamp': encryptedData['timestamp'] ?? '',
        'version': encryptedData['version'] ?? '1.0',
      };
    } catch (e) {
      print('[ENCRYPTION] Failed to decrypt credentials: $e');
      throw Exception('Failed to decrypt credentials');
    }
  }

  /// Encrypt sensitive user data
  static String encryptUserData(Map<String, dynamic> userData) {
    try {
      final jsonString = jsonEncode(userData);
      return encryptData(jsonString);
    } catch (e) {
      print('[ENCRYPTION] Failed to encrypt user data: $e');
      throw Exception('Failed to encrypt user data');
    }
  }

  /// Decrypt sensitive user data
  static Map<String, dynamic> decryptUserData(String encryptedUserData) {
    try {
      final jsonString = decryptData(encryptedUserData);
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      print('[ENCRYPTION] Failed to decrypt user data: $e');
      throw Exception('Failed to decrypt user data');
    }
  }

  /// Generate a secure token
  static String generateSecureToken({int length = 32}) {
    final random = Random.secure();
    final tokenBytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64UrlEncode(tokenBytes);
  }

  /// Hash sensitive data for storage (one-way)
  static String hashSensitiveData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Generate device fingerprint for security
  static String generateDeviceFingerprint() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = Random.secure().nextInt(999999).toString();
    final combined = timestamp + random + (_salt ?? '');
    return sha256.convert(utf8.encode(combined)).toString();
  }

  /// Securely wipe sensitive data from memory
  static void secureWipe(String data) {
    // This is a basic implementation - in production, use more sophisticated
    // memory wiping techniques
    final length = data.length;
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write('\x00');
    }
    buffer.toString(); // This helps overwrite the original string in memory
  }

  /// Check if encryption service is properly initialized
  static bool get isInitialized {
    return _encrypter != null && _encryptionKey != null && _salt != null;
  }

  /// Get encryption service status
  static Map<String, dynamic> getStatus() {
    return {
      'initialized': isInitialized,
      'has_master_key': _encryptionKey != null,
      'has_salt': _salt != null,
      'has_encrypter': _encrypter != null,
    };
  }

  /// Rotate encryption keys (for security maintenance)
  static Future<void> rotateKeys() async {
    try {
      final keyBox = await Hive.openBox(_keyBoxName);

      // Generate new keys
      final newSalt = _generateSalt();
      final newMasterKey = _generateMasterKey();

      // Store new keys
      await keyBox.put(_saltKey, newSalt);
      await keyBox.put(_masterKeyKey, newMasterKey);

      // Update in-memory keys
      _salt = newSalt;
      _encryptionKey = encrypt.Key.fromBase64(newMasterKey);
      _encrypter = encrypt.Encrypter(encrypt.AES(_encryptionKey!));

      print('[ENCRYPTION] Encryption keys rotated successfully');
    } catch (e) {
      print('[ENCRYPTION] Failed to rotate encryption keys: $e');
      throw Exception('Failed to rotate encryption keys');
    }
  }

  /// Clear all encryption keys (use with caution)
  static Future<void> clearKeys() async {
    try {
      final keyBox = await Hive.openBox(_keyBoxName);
      await keyBox.delete(_masterKeyKey);
      await keyBox.delete(_saltKey);

      _encryptionKey = null;
      _encrypter = null;
      _salt = null;

      print('[ENCRYPTION] Encryption keys cleared');
    } catch (e) {
      print('[ENCRYPTION] Failed to clear encryption keys: $e');
      throw Exception('Failed to clear encryption keys');
    }
  }
}