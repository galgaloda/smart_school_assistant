import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Enhanced Firebase Authentication Service with robust features
class FirebaseService {
  static FirebaseFirestore? _firestore;
  static FirebaseAuth? _auth;
  static FirebaseStorage? _storage;
  static bool _isInitialized = false;

  // Session management
  static const String _sessionBoxName = 'auth_session';
  static const String _userSessionKey = 'current_session';
  static const String _lastActivityKey = 'last_activity';
  static const String _deviceIdKey = 'device_id';

  // Initialize Firebase with enhanced configuration
  static Future<void> initializeFirebase() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _firestore = FirebaseFirestore.instance;
      _auth = FirebaseAuth.instance;
      _storage = FirebaseStorage.instance;

      // Configure Firestore settings for offline persistence
      _firestore!.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Initialize session management
      await _initializeSessionManagement();

      // Set up authentication state listener
      _setupAuthStateListener();

      _isInitialized = true;
      print('[FIREBASE] Firebase initialized successfully');
    } catch (e) {
      print('[FIREBASE] Failed to initialize Firebase: $e');
      rethrow;
    }
  }

  // Initialize session management
  static Future<void> _initializeSessionManagement() async {
    try {
      await Hive.openBox(_sessionBoxName);
      print('[FIREBASE] Session management initialized');
    } catch (e) {
      print('[FIREBASE] Failed to initialize session management: $e');
    }
  }

  // Set up authentication state listener
  static void _setupAuthStateListener() {
    _auth?.authStateChanges().listen((User? user) async {
      if (user != null) {
        // User signed in
        await _saveUserSession(user);
        print('[FIREBASE] User signed in: ${user.uid}');
      } else {
        // User signed out
        await _clearUserSession();
        print('[FIREBASE] User signed out');
      }
    });
  }

  // Save user session data
  static Future<void> _saveUserSession(User user) async {
    try {
      final sessionBox = Hive.box(_sessionBoxName);
      final sessionData = {
        'userId': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'emailVerified': user.emailVerified,
        'lastSignIn': DateTime.now().toIso8601String(),
        'deviceId': await _getDeviceId(),
      };

      await sessionBox.put(_userSessionKey, sessionData);
      await sessionBox.put(_lastActivityKey, DateTime.now().toIso8601String());
      print('[FIREBASE] User session saved');
    } catch (e) {
      print('[FIREBASE] Failed to save user session: $e');
    }
  }

  // Clear user session data
  static Future<void> _clearUserSession() async {
    try {
      final sessionBox = Hive.box(_sessionBoxName);
      await sessionBox.delete(_userSessionKey);
      await sessionBox.delete(_lastActivityKey);
      print('[FIREBASE] User session cleared');
    } catch (e) {
      print('[FIREBASE] Failed to clear user session: $e');
    }
  }

  // Get device ID for session tracking
  static Future<String> _getDeviceId() async {
    try {
      final sessionBox = Hive.box(_sessionBoxName);
      String? deviceId = sessionBox.get(_deviceIdKey);

      if (deviceId == null) {
        // Generate a unique device ID
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final random = DateTime.now().microsecondsSinceEpoch.toString();
        final combined = timestamp + random;
        deviceId = sha256.convert(utf8.encode(combined)).toString().substring(0, 16);
        await sessionBox.put(_deviceIdKey, deviceId);
      }

      return deviceId;
    } catch (e) {
      print('[FIREBASE] Failed to get device ID: $e');
      return 'unknown_device';
    }
  }

  // Getters for Firebase services with enhanced error handling
  static FirebaseFirestore get firestore {
    if (!_isInitialized || _firestore == null) {
      throw Exception('Firebase not initialized. Call initializeFirebase() first.');
    }
    return _firestore!;
  }

  static FirebaseAuth get auth {
    if (!_isInitialized || _auth == null) {
      throw Exception('Firebase not initialized. Call initializeFirebase() first.');
    }
    return _auth!;
  }

  static FirebaseStorage get storage {
    if (!_isInitialized || _storage == null) {
      throw Exception('Firebase not initialized. Call initializeFirebase() first.');
    }
    return _storage!;
  }

  // Enhanced authentication check
  static bool get isAuthenticated {
    if (!_isInitialized) return false;

    final authenticated = auth.currentUser != null;
    print('[FIREBASE] Authentication check - isAuthenticated: $authenticated, userId: ${auth.currentUser?.uid}');
    return authenticated;
  }

  // Enhanced current user getter
  static User? get currentUser {
    if (!_isInitialized) return null;

    final user = auth.currentUser;
    if (user != null) {
      print('[FIREBASE] Current user - ID: ${user.uid}, Email: ${user.email}, Verified: ${user.emailVerified}');
    } else {
      print('[FIREBASE] No current user');
    }
    return user;
  }

  // Get user session data
  static Map<String, dynamic>? getUserSession() {
    try {
      final sessionBox = Hive.box(_sessionBoxName);
      return sessionBox.get(_userSessionKey);
    } catch (e) {
      print('[FIREBASE] Failed to get user session: $e');
      return null;
    }
  }

  // Check if user session is valid
  static bool isSessionValid() {
    try {
      final sessionData = getUserSession();
      if (sessionData == null) return false;

      // Check if session is not too old (24 hours)
      final lastActivity = sessionData['lastSignIn'];
      if (lastActivity != null) {
        final lastActivityTime = DateTime.parse(lastActivity);
        final now = DateTime.now();
        final difference = now.difference(lastActivityTime);

        if (difference.inHours > 24) {
          print('[FIREBASE] Session expired');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('[FIREBASE] Failed to validate session: $e');
      return false;
    }
  }

  // Enhanced sign out with session cleanup
  static Future<void> signOut() async {
    try {
      await auth.signOut();
      await _clearUserSession();
      print('[FIREBASE] User signed out successfully');
    } catch (e) {
      print('[FIREBASE] Failed to sign out: $e');
      rethrow;
    }
  }

  // Check network connectivity
  static Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isConnected = connectivityResult != ConnectivityResult.none;
      print('[FIREBASE] Connectivity check - Result: $connectivityResult, IsOnline: $isConnected');
      return isConnected;
    } catch (e) {
      print('[FIREBASE] Connectivity check failed: $e');
      return false;
    }
  }

  // Update user activity timestamp
  static Future<void> updateUserActivity() async {
    try {
      final sessionBox = Hive.box(_sessionBoxName);
      await sessionBox.put(_lastActivityKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('[FIREBASE] Failed to update user activity: $e');
    }
  }

  // Get user profile data from Firestore
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('[FIREBASE] Failed to get user profile: $e');
      return null;
    }
  }

  // Update user profile in Firestore
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await firestore.collection('users').doc(userId).update(data);
      print('[FIREBASE] User profile updated successfully');
    } catch (e) {
      print('[FIREBASE] Failed to update user profile: $e');
      rethrow;
    }
  }

  // Enhanced password reset
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await auth.sendPasswordResetEmail(email: email);
      print('[FIREBASE] Password reset email sent to: $email');
    } catch (e) {
      print('[FIREBASE] Failed to send password reset email: $e');
      rethrow;
    }
  }

  // Enhanced email verification
  static Future<void> sendEmailVerification() async {
    try {
      final user = auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print('[FIREBASE] Email verification sent to: ${user.email}');
      }
    } catch (e) {
      print('[FIREBASE] Failed to send email verification: $e');
      rethrow;
    }
  }

  // Check if email is verified
  static bool get isEmailVerified {
    return auth.currentUser?.emailVerified ?? false;
  }

  // Re-authenticate user (for sensitive operations)
  static Future<void> reauthenticateUser(String password) async {
    try {
      final user = auth.currentUser;
      if (user != null && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
        print('[FIREBASE] User re-authenticated successfully');
      }
    } catch (e) {
      print('[FIREBASE] Failed to re-authenticate user: $e');
      rethrow;
    }
  }

  // Update user email (requires re-authentication)
  static Future<void> updateEmail(String newEmail, String password) async {
    try {
      await reauthenticateUser(password);
      await auth.currentUser?.updateEmail(newEmail);
      await auth.currentUser?.sendEmailVerification();
      print('[FIREBASE] Email updated successfully');
    } catch (e) {
      print('[FIREBASE] Failed to update email: $e');
      rethrow;
    }
  }

  // Update user password (requires re-authentication)
  static Future<void> updatePassword(String newPassword, String currentPassword) async {
    try {
      await reauthenticateUser(currentPassword);
      await auth.currentUser?.updatePassword(newPassword);
      print('[FIREBASE] Password updated successfully');
    } catch (e) {
      print('[FIREBASE] Failed to update password: $e');
      rethrow;
    }
  }

  // Delete user account
  static Future<void> deleteAccount(String password) async {
    try {
      await reauthenticateUser(password);
      await auth.currentUser?.delete();
      await _clearUserSession();
      print('[FIREBASE] Account deleted successfully');
    } catch (e) {
      print('[FIREBASE] Failed to delete account: $e');
      rethrow;
    }
  }
}

// Firebase configuration for different platforms
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Firebase configuration for smart-school-assistant-b9340 project
    return const FirebaseOptions(
      apiKey: 'AIzaSyDRuNh2zL4Q4jLdnwdAv-qHiccBkPzaJzk',
      appId: '1:893583360512:android:2c331acced876ff7d98ee5',
      messagingSenderId: '893583360512',
      projectId: 'smart-school-assistant-b9340',
      storageBucket: 'smart-school-assistant-b9340.firebasestorage.app',
    );
  }
}