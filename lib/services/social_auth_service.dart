import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';
import 'firebase_service.dart';
import 'comprehensive_auth_service.dart';

/// Social Authentication Service
class SocialAuthService {
  static const String _socialAuthBoxName = 'social_auth_data';
  static const String _linkedAccountsKey = 'linked_accounts';

  static bool _isInitialized = false;

  // OAuth configuration (these would be set from environment variables in production)

  /// Initialize social auth service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.openBox(_socialAuthBoxName);
      _isInitialized = true;
      print('[SOCIAL_AUTH] Social authentication service initialized');
    } catch (e) {
      print('[SOCIAL_AUTH] Failed to initialize social auth service: $e');
      rethrow;
    }
  }

  /// Sign in with Google
  static Future<SocialAuthResult> signInWithGoogle() async {
    try {
      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.socialAuthAttempt,
        'Google sign-in attempt',
      );

      // Create Google Auth Provider
      final googleProvider = firebase_auth.GoogleAuthProvider();

      // Configure scopes
      googleProvider.addScope('email');
      googleProvider.addScope('profile');

      // For web, this will open a popup
      // For mobile, this will use the native Google Sign-In
      final userCredential = await FirebaseService.auth.signInWithPopup(googleProvider);

      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;

        // Get additional user info from Google
        final additionalUserInfo = userCredential.additionalUserInfo;

        // Create or update user profile
        final user = await _createOrUpdateUserFromSocialAuth(
          firebaseUser,
          SocialProvider.google,
          additionalUserInfo?.profile,
        );

        // Link the account
        await _linkSocialAccount(user.id, SocialProvider.google, firebaseUser.uid);

        ComprehensiveAuthService.logAuthEvent(
          AuthEventType.socialAuthSuccessful,
          'Google sign-in successful',
          userId: user.id,
        );

        return SocialAuthResult(
          success: true,
          user: user,
          provider: SocialProvider.google,
        );
      } else {
        ComprehensiveAuthService.logAuthEvent(
          AuthEventType.socialAuthFailed,
          'Google sign-in failed: No user returned',
        );

        return SocialAuthResult(
          success: false,
          error: 'Google sign-in failed',
        );
      }

    } catch (e) {
      print('[SOCIAL_AUTH] Google sign-in error: $e');

      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.socialAuthFailed,
        'Google sign-in error: $e',
      );

      return SocialAuthResult(
        success: false,
        error: 'Google sign-in failed: ${e.toString()}',
      );
    }
  }

  /// Sign in with Facebook
  static Future<SocialAuthResult> signInWithFacebook() async {
    try {
      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.socialAuthAttempt,
        'Facebook sign-in attempt',
      );

      final facebookProvider = firebase_auth.FacebookAuthProvider();

      // Configure permissions
      facebookProvider.addScope('email');
      facebookProvider.addScope('public_profile');

      final userCredential = await FirebaseService.auth.signInWithPopup(facebookProvider);

      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;
        final additionalUserInfo = userCredential.additionalUserInfo;

        final user = await _createOrUpdateUserFromSocialAuth(
          firebaseUser,
          SocialProvider.facebook,
          additionalUserInfo?.profile,
        );

        await _linkSocialAccount(user.id, SocialProvider.facebook, firebaseUser.uid);

        ComprehensiveAuthService.logAuthEvent(
          AuthEventType.socialAuthSuccessful,
          'Facebook sign-in successful',
          userId: user.id,
        );

        return SocialAuthResult(
          success: true,
          user: user,
          provider: SocialProvider.facebook,
        );
      } else {
        ComprehensiveAuthService.logAuthEvent(
          AuthEventType.socialAuthFailed,
          'Facebook sign-in failed: No user returned',
        );

        return SocialAuthResult(
          success: false,
          error: 'Facebook sign-in failed',
        );
      }

    } catch (e) {
      print('[SOCIAL_AUTH] Facebook sign-in error: $e');

      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.socialAuthFailed,
        'Facebook sign-in error: $e',
      );

      return SocialAuthResult(
        success: false,
        error: 'Facebook sign-in failed: ${e.toString()}',
      );
    }
  }

  /// Sign in with Apple (iOS only)
  static Future<SocialAuthResult> signInWithApple() async {
    try {
      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.socialAuthAttempt,
        'Apple sign-in attempt',
      );

      final appleProvider = firebase_auth.AppleAuthProvider();

      final userCredential = await FirebaseService.auth.signInWithPopup(appleProvider);

      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;
        final additionalUserInfo = userCredential.additionalUserInfo;

        final user = await _createOrUpdateUserFromSocialAuth(
          firebaseUser,
          SocialProvider.apple,
          additionalUserInfo?.profile,
        );

        await _linkSocialAccount(user.id, SocialProvider.apple, firebaseUser.uid);

        ComprehensiveAuthService.logAuthEvent(
          AuthEventType.socialAuthSuccessful,
          'Apple sign-in successful',
          userId: user.id,
        );

        return SocialAuthResult(
          success: true,
          user: user,
          provider: SocialProvider.apple,
        );
      } else {
        ComprehensiveAuthService.logAuthEvent(
          AuthEventType.socialAuthFailed,
          'Apple sign-in failed: No user returned',
        );

        return SocialAuthResult(
          success: false,
          error: 'Apple sign-in failed',
        );
      }

    } catch (e) {
      print('[SOCIAL_AUTH] Apple sign-in error: $e');

      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.socialAuthFailed,
        'Apple sign-in error: $e',
      );

      return SocialAuthResult(
        success: false,
        error: 'Apple sign-in failed: ${e.toString()}',
      );
    }
  }

  /// Link social account to existing user
  static Future<SocialLinkResult> linkSocialAccount(String userId, SocialProvider provider) async {
    try {
      late firebase_auth.AuthProvider authProvider;

      switch (provider) {
        case SocialProvider.google:
          authProvider = firebase_auth.GoogleAuthProvider();
          break;
        case SocialProvider.facebook:
          authProvider = firebase_auth.FacebookAuthProvider();
          break;
        case SocialProvider.apple:
          authProvider = firebase_auth.AppleAuthProvider();
          break;
        default:
          return SocialLinkResult(
            success: false,
            error: 'Unsupported provider',
          );
      }

      // Link the account
      final userCredential = await FirebaseService.auth.currentUser?.linkWithPopup(authProvider);

      if (userCredential != null) {
        await _linkSocialAccount(userId, provider, userCredential.user!.uid);

        ComprehensiveAuthService.logAuthEvent(
          AuthEventType.socialAccountLinked,
          'Social account linked: $provider',
          userId: userId,
        );

        return SocialLinkResult(success: true);
      } else {
        return SocialLinkResult(
          success: false,
          error: 'Failed to link account',
        );
      }

    } catch (e) {
      print('[SOCIAL_AUTH] Link account error: $e');

      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.socialAccountLinkFailed,
        'Social account link failed: $e',
        userId: userId,
      );

      return SocialLinkResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Unlink social account
  static Future<bool> unlinkSocialAccount(String userId, SocialProvider provider) async {
    try {
      final socialAuthBox = await Hive.openBox(_socialAuthBoxName);
      final linkedAccounts = socialAuthBox.get(_linkedAccountsKey, defaultValue: <String, dynamic>{});

      if (linkedAccounts is Map) {
        final userKey = 'user_$userId';
        final userAccounts = linkedAccounts[userKey] as Map<String, dynamic>? ?? {};

        userAccounts.remove(provider.toString());
        linkedAccounts[userKey] = userAccounts;

        await socialAuthBox.put(_linkedAccountsKey, linkedAccounts);

        ComprehensiveAuthService.logAuthEvent(
          AuthEventType.socialAccountUnlinked,
          'Social account unlinked: $provider',
          userId: userId,
        );

        return true;
      }

      return false;

    } catch (e) {
      print('[SOCIAL_AUTH] Unlink account error: $e');

      ComprehensiveAuthService.logAuthEvent(
        AuthEventType.error,
        'Social account unlink error: $e',
        userId: userId,
      );

      return false;
    }
  }

  /// Get linked social accounts for user
  static Future<List<SocialProvider>> getLinkedAccounts(String userId) async {
    try {
      final socialAuthBox = await Hive.openBox(_socialAuthBoxName);
      final linkedAccounts = socialAuthBox.get(_linkedAccountsKey, defaultValue: <String, dynamic>{});

      if (linkedAccounts is Map) {
        final userKey = 'user_$userId';
        final userAccounts = linkedAccounts[userKey] as Map<String, dynamic>? ?? {};

        return userAccounts.keys
            .map((provider) => _parseSocialProvider(provider))
            .where((provider) => provider != null)
            .cast<SocialProvider>()
            .toList();
      }

      return [];

    } catch (e) {
      print('[SOCIAL_AUTH] Get linked accounts error: $e');
      return [];
    }
  }

  /// Create or update user from social authentication
  static Future<User> _createOrUpdateUserFromSocialAuth(
    firebase_auth.User firebaseUser,
    SocialProvider provider,
    Map<String, dynamic>? profile,
  ) async {
    try {
      // Check if user already exists
      final usersBox = Hive.box<User>('users');
      User? existingUser = usersBox.get(firebaseUser.uid);

      if (existingUser != null) {
        // Update existing user with social auth info
        existingUser.displayName = firebaseUser.displayName ?? existingUser.displayName;
        existingUser.photoUrl = firebaseUser.photoURL ?? existingUser.photoUrl;
        existingUser.lastLoginAt = DateTime.now();

        await usersBox.put(firebaseUser.uid, existingUser);
        await _updateUserInFirestore(existingUser);

        return existingUser;
      } else {
        // Create new user from social auth
        final newUser = User(
          id: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
          photoUrl: firebaseUser.photoURL,
          role: 'student', // Default role for social auth users
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
          isActive: true,
          schoolName: profile?['school'] ?? profile?['school_name'],
        );

        await usersBox.put(firebaseUser.uid, newUser);
        await _saveUserToFirestore(newUser);

        return newUser;
      }

    } catch (e) {
      print('[SOCIAL_AUTH] Create/update user error: $e');
      rethrow;
    }
  }

  /// Link social account internally
  static Future<void> _linkSocialAccount(String userId, SocialProvider provider, String providerId) async {
    try {
      final socialAuthBox = await Hive.openBox(_socialAuthBoxName);
      final linkedAccounts = socialAuthBox.get(_linkedAccountsKey, defaultValue: <String, dynamic>{});

      if (linkedAccounts is Map) {
        final userKey = 'user_$userId';
        final userAccounts = linkedAccounts[userKey] as Map<String, dynamic>? ?? {};

        userAccounts[provider.toString()] = {
          'providerId': providerId,
          'linkedAt': DateTime.now().toIso8601String(),
        };

        linkedAccounts[userKey] = userAccounts;
        await socialAuthBox.put(_linkedAccountsKey, linkedAccounts);
      }

    } catch (e) {
      print('[SOCIAL_AUTH] Link social account error: $e');
    }
  }

  /// Save user to Firestore
  static Future<void> _saveUserToFirestore(User user) async {
    try {
      await FirebaseService.firestore.collection('users').doc(user.id).set({
        'email': user.email,
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'role': user.role,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'lastLoginAt': Timestamp.fromDate(user.lastLoginAt ?? DateTime.now()),
        'isActive': user.isActive,
        'schoolName': user.schoolName,
        'authProvider': 'social',
        'deviceId': await _getDeviceId(),
        'lastDeviceSync': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('[SOCIAL_AUTH] Save user to Firestore error: $e');
    }
  }

  /// Update user in Firestore
  static Future<void> _updateUserInFirestore(User user) async {
    try {
      await FirebaseService.firestore.collection('users').doc(user.id).update({
        'displayName': user.displayName,
        'photoUrl': user.photoUrl,
        'lastLoginAt': Timestamp.fromDate(user.lastLoginAt ?? DateTime.now()),
        'lastDeviceSync': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('[SOCIAL_AUTH] Update user in Firestore error: $e');
    }
  }

  /// Get device ID
  static Future<String> _getDeviceId() async {
    try {
      // This would typically use device_info_plus
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      return 'device_${timestamp.substring(timestamp.length - 8)}';
    } catch (e) {
      return 'unknown_device';
    }
  }

  /// Parse social provider from string
  static SocialProvider? _parseSocialProvider(String providerString) {
    switch (providerString.toLowerCase()) {
      case 'google':
        return SocialProvider.google;
      case 'facebook':
        return SocialProvider.facebook;
      case 'apple':
        return SocialProvider.apple;
      default:
        return null;
    }
  }

  /// Get available social providers
  static List<SocialProvider> getAvailableProviders() {
    return [
      SocialProvider.google,
      SocialProvider.facebook,
      SocialProvider.apple,
    ];
  }

  /// Check if social provider is available on current platform
  static bool isProviderAvailable(SocialProvider provider) {
    // For web, all providers are available
    // For mobile, check platform-specific availability
    return true; // Simplified for this implementation
  }

  /// Get social auth status for user
  static Future<Map<String, dynamic>> getSocialAuthStatus(String userId) async {
    final linkedAccounts = await getLinkedAccounts(userId);

    return {
      'hasLinkedAccounts': linkedAccounts.isNotEmpty,
      'linkedProviders': linkedAccounts.map((p) => p.toString()).toList(),
      'availableProviders': getAvailableProviders()
          .where((p) => !linkedAccounts.contains(p))
          .map((p) => p.toString())
          .toList(),
    };
  }
}

/// Social Authentication Providers
enum SocialProvider {
  google,
  facebook,
  apple,
}

/// Social Authentication Result
class SocialAuthResult {
  final bool success;
  final User? user;
  final SocialProvider? provider;
  final String? error;

  SocialAuthResult({
    required this.success,
    this.user,
    this.provider,
    this.error,
  });
}

/// Social Account Link Result
class SocialLinkResult {
  final bool success;
  final String? error;

  SocialLinkResult({
    required this.success,
    this.error,
  });
}