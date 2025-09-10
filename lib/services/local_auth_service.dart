import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models.dart';

class LocalAuthService {
  static const String _authBoxName = 'local_auth';
  static const String _usersKey = 'authenticated_users';

  /// Initialize local authentication service
  static Future<void> initialize() async {
    await Hive.openBox(_authBoxName);
  }

  /// Generate a salt for password hashing
  static String _generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    return base64.encode(bytes);
  }

  /// Hash password with salt
  static String _hashPassword(String password, String salt) {
    final saltedPassword = password + salt;
    final bytes = utf8.encode(saltedPassword);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Register a user locally for offline authentication
  static Future<bool> registerLocalUser(String email, String password, User user) async {
    try {
      final authBox = Hive.box(_authBoxName);

      // Generate salt and hash password
      final salt = _generateSalt();
      final hashedPassword = _hashPassword(password, salt);

      // Store salt
      await authBox.put('${email}_salt', salt);

      // Store hashed password
      await authBox.put('${email}_password', hashedPassword);

      // Store user data as map
      final userData = {
        'id': user.id,
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'role': user.role,
        'createdAt': user.createdAt.toIso8601String(),
        'lastLoginAt': user.lastLoginAt.toIso8601String(),
        'isActive': user.isActive,
        'schoolName': user.schoolName,
        'schoolAddress': user.schoolAddress,
        'schoolPhone': user.schoolPhone,
        'isSynced': user.isSynced,
        'lastUpdated': user.lastUpdated?.toIso8601String(),
        'userId': user.userId,
        'syncId': user.syncId,
      };
      await authBox.put('${email}_user', userData);

      // Add to authenticated users list
      final authenticatedUsers = authBox.get(_usersKey, defaultValue: <String>[]);
      if (authenticatedUsers is List<String> && !authenticatedUsers.contains(email)) {
        authenticatedUsers.add(email);
        await authBox.put(_usersKey, authenticatedUsers);
      }

      return true;
    } catch (e) {
      print('Error registering local user: $e');
      return false;
    }
  }

  /// Authenticate user locally (offline)
  static Future<User?> authenticateLocalUser(String email, String password) async {
    try {
      final authBox = Hive.box(_authBoxName);

      // Get stored salt and hashed password
      final salt = authBox.get('${email}_salt');
      final storedHash = authBox.get('${email}_password');

      if (salt == null || storedHash == null) {
        return null; // User not found
      }

      // Hash provided password with stored salt
      final hashedPassword = _hashPassword(password, salt);

      // Compare hashes
      if (hashedPassword == storedHash) {
        // Authentication successful, return user data
        final userJson = authBox.get('${email}_user');
        if (userJson != null && userJson is Map) {
          final data = Map<String, dynamic>.from(userJson);
          return User(
            id: data['id'],
            email: data['email'],
            displayName: data['displayName'],
            photoUrl: data['photoUrl'],
            role: data['role'],
            createdAt: DateTime.parse(data['createdAt']),
            lastLoginAt: DateTime.parse(data['lastLoginAt']),
            isActive: data['isActive'] ?? true,
            schoolName: data['schoolName'],
            schoolAddress: data['schoolAddress'],
            schoolPhone: data['schoolPhone'],
            isSynced: data['isSynced'] ?? false,
            lastUpdated: data['lastUpdated'] != null ? DateTime.parse(data['lastUpdated']) : null,
            userId: data['userId'],
            syncId: data['syncId'],
          );
        }
      }

      return null; // Authentication failed
    } catch (e) {
      print('Error authenticating local user: $e');
      return null;
    }
  }

  /// Check if user is registered locally
  static Future<bool> isUserRegisteredLocally(String email) async {
    try {
      final authBox = Hive.box(_authBoxName);
      final salt = authBox.get('${email}_salt');
      return salt != null;
    } catch (e) {
      return false;
    }
  }

  /// Get locally stored user data
  static Future<User?> getLocalUser(String email) async {
    try {
      final authBox = Hive.box(_authBoxName);
      final userJson = authBox.get('${email}_user');

      if (userJson != null && userJson is Map) {
        final data = Map<String, dynamic>.from(userJson);
        return User(
          id: data['id'],
          email: data['email'],
          displayName: data['displayName'],
          photoUrl: data['photoUrl'],
          role: data['role'],
          createdAt: DateTime.parse(data['createdAt']),
          lastLoginAt: DateTime.parse(data['lastLoginAt']),
          isActive: data['isActive'] ?? true,
          schoolName: data['schoolName'],
          schoolAddress: data['schoolAddress'],
          schoolPhone: data['schoolPhone'],
          isSynced: data['isSynced'] ?? false,
          lastUpdated: data['lastUpdated'] != null ? DateTime.parse(data['lastUpdated']) : null,
          userId: data['userId'],
          syncId: data['syncId'],
        );
      }

      return null;
    } catch (e) {
      print('Error getting local user: $e');
      return null;
    }
  }

  /// Update local user data
  static Future<bool> updateLocalUser(String email, User updatedUser) async {
    try {
      final authBox = Hive.box(_authBoxName);
      final userData = {
        'id': updatedUser.id,
        'email': updatedUser.email,
        'displayName': updatedUser.displayName,
        'photoUrl': updatedUser.photoUrl,
        'role': updatedUser.role,
        'createdAt': updatedUser.createdAt.toIso8601String(),
        'lastLoginAt': updatedUser.lastLoginAt.toIso8601String(),
        'isActive': updatedUser.isActive,
        'schoolName': updatedUser.schoolName,
        'schoolAddress': updatedUser.schoolAddress,
        'schoolPhone': updatedUser.schoolPhone,
        'isSynced': updatedUser.isSynced,
        'lastUpdated': updatedUser.lastUpdated?.toIso8601String(),
        'userId': updatedUser.userId,
        'syncId': updatedUser.syncId,
      };
      await authBox.put('${email}_user', userData);
      return true;
    } catch (e) {
      print('Error updating local user: $e');
      return false;
    }
  }

  /// Remove local user authentication
  static Future<bool> removeLocalUser(String email) async {
    try {
      final authBox = Hive.box(_authBoxName);

      // Remove user data
      await authBox.delete('${email}_salt');
      await authBox.delete('${email}_password');
      await authBox.delete('${email}_user');

      // Remove from authenticated users list
      final authenticatedUsers = authBox.get(_usersKey, defaultValue: <String>[]);
      if (authenticatedUsers is List<String>) {
        authenticatedUsers.remove(email);
        await authBox.put(_usersKey, authenticatedUsers);
      }

      return true;
    } catch (e) {
      print('Error removing local user: $e');
      return false;
    }
  }

  /// Get all locally authenticated users
  static Future<List<String>> getAuthenticatedUsers() async {
    try {
      final authBox = Hive.box(_authBoxName);
      final users = authBox.get(_usersKey, defaultValue: <String>[]);
      return users is List<String> ? users : [];
    } catch (e) {
      return [];
    }
  }

  /// Clear all local authentication data
  static Future<void> clearAllLocalAuth() async {
    try {
      final authBox = Hive.box(_authBoxName);
      await authBox.clear();
    } catch (e) {
      print('Error clearing local auth: $e');
    }
  }

  /// Sync Firebase user to local storage
  static Future<bool> syncFirebaseUserToLocal(firebase_auth.User firebaseUser, String password) async {
    try {
      final usersBox = Hive.box<User>('users');

      // Get user from main users box
      User? localUser;
      try {
        localUser = usersBox.values.firstWhere(
          (user) => user.id == firebaseUser.uid,
        );
      } catch (e) {
        // User not found in main box
        return false;
      }

      // Register for local authentication
      return await registerLocalUser(firebaseUser.email ?? '', password, localUser);
    
      return false;
    } catch (e) {
      print('Error syncing Firebase user to local: $e');
      return false;
    }
  }
}