import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:crypto/crypto.dart';
import '../models.dart';
import '../models/user_role.dart' as user_role;
import 'firebase_service.dart';
import 'local_auth_service.dart';

/// Comprehensive Authentication Service
/// Orchestrates all authentication components including Firebase, local auth,
/// session management, RBAC, biometric auth, and security features
class ComprehensiveAuthService {
  static final ComprehensiveAuthService _instance = ComprehensiveAuthService._internal();
  factory ComprehensiveAuthService() => _instance;
  ComprehensiveAuthService._internal();

  // Services

  // State management
  final StreamController<AuthState> _authStateController = StreamController<AuthState>.broadcast();
  final StreamController<AuthEvent> _authEventController = StreamController<AuthEvent>.broadcast();

  // Session management
  static const String _sessionBoxName = 'auth_sessions';
  static const String _currentSessionKey = 'current_session';

  // Connectivity
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  List<ConnectivityResult> _currentConnectivity = [ConnectivityResult.none];

  // Initialization flag
  bool _isInitialized = false;

  // Getters
  Stream<AuthState> get authStateStream => _authStateController.stream;
  Stream<AuthEvent> get authEventStream => _authEventController.stream;
  AuthState get currentAuthState => _getCurrentAuthState();
  bool get isOnline => _currentConnectivity.any((result) => result != ConnectivityResult.none);
  bool get isAuthenticated => FirebaseService.isAuthenticated;
  user_role.User? get currentUser => user_role.AccessControlManager.getCurrentUser();

  /// Initialize the comprehensive authentication service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      await FirebaseService.initializeFirebase();

      // Initialize local auth
      await LocalAuthService.initialize();

      // Initialize session management
      await _initializeSessionManagement();

      // Setup connectivity monitoring
      await _setupConnectivityMonitoring();

      // Setup auth state listeners
      _setupAuthStateListeners();

      // Load existing session
      await _loadExistingSession();

      _isInitialized = true;
      _logAuthEvent(AuthEventType.serviceInitialized, 'Comprehensive auth service initialized successfully');

    } catch (e) {
      _logAuthEvent(AuthEventType.error, 'Failed to initialize auth service: $e');
      rethrow;
    }
  }

  /// Setup connectivity monitoring
  Future<void> _setupConnectivityMonitoring() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final wasOnline = _currentConnectivity.any((result) => result != ConnectivityResult.none);
        final isNowOnline = results.any((result) => result != ConnectivityResult.none);

        _currentConnectivity = results;

        if (wasOnline != isNowOnline) {
          _logAuthEvent(
            AuthEventType.connectivityChanged,
            'Connectivity changed: ${isNowOnline ? 'online' : 'offline'}'
          );

          // Trigger sync if coming back online
          if (isNowOnline && !_authStateController.isClosed) {
            _authStateController.add(AuthState.connectivityRestored);
          }
        }
      }
    );

    // Get initial connectivity
    _currentConnectivity = await Connectivity().checkConnectivity();
  }

  /// Setup authentication state listeners
  void _setupAuthStateListeners() {
    FirebaseService.auth.authStateChanges().listen((firebase_auth.User? firebaseUser) {
      if (firebaseUser != null) {
        _handleFirebaseUserAuthenticated(firebaseUser);
      } else {
        _handleFirebaseUserSignedOut();
      }
    });
  }

  /// Initialize session management
  Future<void> _initializeSessionManagement() async {
    await Hive.openBox(_sessionBoxName);
  }

  /// Load existing session on startup
  Future<void> _loadExistingSession() async {
    try {
      final sessionBox = Hive.box(_sessionBoxName);
      final sessionData = sessionBox.get(_currentSessionKey);

      if (sessionData != null && sessionData is Map) {
        final session = AuthSession.fromJson(Map<String, dynamic>.from(sessionData));

        // Validate session
        if (session.isValid && FirebaseService.isAuthenticated) {
          _authStateController.add(AuthState.authenticated);
          _logAuthEvent(AuthEventType.sessionRestored, 'Existing session restored');
        } else {
          // Session expired or invalid
          await clearSession();
          _authStateController.add(AuthState.unauthenticated);
        }
      } else {
        _authStateController.add(AuthState.unauthenticated);
      }
    } catch (e) {
      _logAuthEvent(AuthEventType.error, 'Failed to load existing session: $e');
      _authStateController.add(AuthState.unauthenticated);
    }
  }

  /// Handle Firebase user authentication
  Future<void> _handleFirebaseUserAuthenticated(firebase_auth.User firebaseUser) async {
    try {
      // Get or create user profile
      final userProfile = await _getOrCreateUserProfile(firebaseUser);

      // Create access control user
      final accessUser = user_role.User(
        id: userProfile.id,
        email: userProfile.email,
        displayName: userProfile.displayName ?? '',
        role: _mapStringToUserRole(userProfile.role),
        permissions: user_role.User.getDefaultPermissions(_mapStringToUserRole(userProfile.role)),
        createdAt: userProfile.createdAt,
        lastLoginAt: DateTime.now(),
      );

      // Set current user
      user_role.AccessControlManager.setCurrentUser(accessUser);

      // Create and save session
      final session = AuthSession(
        userId: firebaseUser.uid,
        deviceId: await _getDeviceId(),
        loginTime: DateTime.now(),
        lastActivity: DateTime.now(),
        isOnline: isOnline,
      );

      await _saveSession(session);

      // Update auth state
      _authStateController.add(AuthState.authenticated);

      _logAuthEvent(AuthEventType.loginSuccessful, 'User authenticated: ${firebaseUser.email}');

    } catch (e) {
      _logAuthEvent(AuthEventType.error, 'Failed to handle Firebase authentication: $e');
      _authStateController.add(AuthState.error);
    }
  }

  /// Handle Firebase user sign out
  Future<void> _handleFirebaseUserSignedOut() async {
    await clearSession();
    user_role.AccessControlManager.setCurrentUser(null);
    _authStateController.add(AuthState.unauthenticated);
    _logAuthEvent(AuthEventType.logoutSuccessful, 'User signed out');
  }

  /// Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword(String email, String password) async {
    try {
      _logAuthEvent(AuthEventType.loginAttempt, 'Login attempt for: $email');

      if (!isOnline) {
        // Try offline authentication
        return await _signInOffline(email, password);
      }

      // Online authentication
      final userCredential = await FirebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Register for local auth if not already registered
      await LocalAuthService.registerLocalUser(email, password, await _getUserFromFirebase(userCredential.user!));

      _logAuthEvent(AuthEventType.loginSuccessful, 'Online login successful for: $email');
      return AuthResult.success;

    } catch (e) {
      _logAuthEvent(AuthEventType.loginFailed, 'Login failed for $email: $e');

      // Try offline login as fallback
      if (isOnline) {
        try {
          return await _signInOffline(email, password);
        } catch (offlineError) {
          // Both online and offline failed
        }
      }

      return AuthResult.failure;
    }
  }

  /// Sign in offline
  Future<AuthResult> _signInOffline(String email, String password) async {
    final localUser = await LocalAuthService.authenticateLocalUser(email, password);

    if (localUser != null) {
      // Create access control user
      final accessUser = user_role.User(
        id: localUser.id,
        email: localUser.email,
        displayName: localUser.displayName ?? '',
        role: _mapStringToUserRole(localUser.role),
        permissions: user_role.User.getDefaultPermissions(_mapStringToUserRole(localUser.role)),
        createdAt: localUser.createdAt,
        lastLoginAt: DateTime.now(),
      );

      user_role.AccessControlManager.setCurrentUser(accessUser);

      // Create offline session
      final session = AuthSession(
        userId: localUser.id,
        deviceId: await _getDeviceId(),
        loginTime: DateTime.now(),
        lastActivity: DateTime.now(),
        isOnline: false,
      );

      await _saveSession(session);
      _authStateController.add(AuthState.authenticated);

      _logAuthEvent(AuthEventType.offlineLoginSuccessful, 'Offline login successful for: $email');
      return AuthResult.success;
    }

    return AuthResult.failure;
  }

  /// Sign up with email and password
  Future<AuthResult> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
    String role,
    {String? schoolName}
  ) async {
    try {
      _logAuthEvent(AuthEventType.registrationAttempt, 'Registration attempt for: $email');

      if (!isOnline) {
        return AuthResult.failure; // Registration requires internet
      }

      // Create Firebase user
      final userCredential = await FirebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await userCredential.user?.updateDisplayName(displayName);

      // Create user profile
      final user = User(
        id: userCredential.user!.uid,
        email: email,
        displayName: displayName,
        role: role,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
        schoolName: schoolName,
      );

      // Save to Firestore
      await _saveUserToFirestore(user);

      // Register for local auth
      await LocalAuthService.registerLocalUser(email, password, user);

      _logAuthEvent(AuthEventType.registrationSuccessful, 'Registration successful for: $email');
      return AuthResult.success;

    } catch (e) {
      _logAuthEvent(AuthEventType.registrationFailed, 'Registration failed for $email: $e');
      return AuthResult.failure;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await FirebaseService.signOut();
      await clearSession();
      _logAuthEvent(AuthEventType.logoutSuccessful, 'User signed out successfully');
    } catch (e) {
      _logAuthEvent(AuthEventType.error, 'Sign out failed: $e');
      rethrow;
    }
  }

  /// Clear session
  Future<void> clearSession() async {
    try {
      final sessionBox = Hive.box(_sessionBoxName);
      await sessionBox.delete(_currentSessionKey);
      user_role.AccessControlManager.setCurrentUser(null);
      _authStateController.add(AuthState.unauthenticated);
    } catch (e) {
      _logAuthEvent(AuthEventType.error, 'Failed to clear session: $e');
    }
  }

  /// Save session
  Future<void> _saveSession(AuthSession session) async {
    try {
      final sessionBox = Hive.box(_sessionBoxName);
      await sessionBox.put(_currentSessionKey, session.toJson());
    } catch (e) {
      _logAuthEvent(AuthEventType.error, 'Failed to save session: $e');
    }
  }

  /// Get device ID
  Future<String> _getDeviceId() async {
    try {
      final sessionBox = Hive.box(_sessionBoxName);
      String? deviceId = sessionBox.get('device_id');

      if (deviceId == null) {
        final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final random = DateTime.now().microsecondsSinceEpoch.toString();
        final combined = timestamp + random;
        deviceId = sha256.convert(utf8.encode(combined)).toString().substring(0, 16);
        await sessionBox.put('device_id', deviceId);
      }

      return deviceId;
    } catch (e) {
      return 'unknown_device';
    }
  }

  /// Get or create user profile
  Future<User> _getOrCreateUserProfile(firebase_auth.User firebaseUser) async {
    try {
      // Try to get from local storage first
      final usersBox = Hive.box<User>('users');
      User? localUser = usersBox.get(firebaseUser.uid);

      if (localUser != null) {
        return localUser;
      }

      // Try to get from Firestore
      final userDoc = await FirebaseService.firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        localUser = User(
          id: firebaseUser.uid,
          email: userData['email'] ?? firebaseUser.email ?? '',
          displayName: userData['displayName'] ?? firebaseUser.displayName,
          role: userData['role'] ?? 'student',
          createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastLoginAt: DateTime.now(),
          isActive: userData['isActive'] ?? true,
          schoolName: userData['schoolName'],
        );

        // Save to local storage
        await usersBox.put(firebaseUser.uid, localUser);
        return localUser;
      }

      // Create new user profile
      localUser = User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        role: 'student', // Default role
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
      );

      await usersBox.put(firebaseUser.uid, localUser);
      await _saveUserToFirestore(localUser);

      return localUser;

    } catch (e) {
      _logAuthEvent(AuthEventType.error, 'Failed to get/create user profile: $e');
      rethrow;
    }
  }

  /// Get user from Firebase
  Future<User> _getUserFromFirebase(firebase_auth.User firebaseUser) async {
    final usersBox = Hive.box<User>('users');
    User? user = usersBox.get(firebaseUser.uid);

    user ??= await _getOrCreateUserProfile(firebaseUser);

    return user;
  }

  /// Save user to Firestore
  Future<void> _saveUserToFirestore(User user) async {
    try {
      await FirebaseService.firestore.collection('users').doc(user.id).set({
        'email': user.email,
        'displayName': user.displayName,
        'role': user.role,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'lastLoginAt': Timestamp.fromDate(user.lastLoginAt ?? DateTime.now()),
        'isActive': user.isActive,
        'schoolName': user.schoolName,
        'deviceId': await _getDeviceId(),
        'lastDeviceSync': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      _logAuthEvent(AuthEventType.error, 'Failed to save user to Firestore: $e');
    }
  }

  /// Map string role to UserRole enum
  user_role.UserRole _mapStringToUserRole(String roleString) {
    switch (roleString.toLowerCase()) {
      case 'admin':
        return user_role.UserRole.admin;
      case 'principal':
        return user_role.UserRole.principal;
      case 'teacher':
        return user_role.UserRole.teacher;
      case 'staff':
        return user_role.UserRole.staff;
      case 'parent':
        return user_role.UserRole.parent;
      case 'student':
      default:
        return user_role.UserRole.student;
    }
  }

  /// Get current auth state
  AuthState _getCurrentAuthState() {
    if (!FirebaseService.isAuthenticated) {
      return AuthState.unauthenticated;
    }

    if (!isOnline) {
      return AuthState.offlineAuthenticated;
    }

    return AuthState.authenticated;
  }

  /// Log authentication event (public method)
  static void logAuthEvent(AuthEventType type, String message, {String? userId, String? deviceId}) {
    final event = AuthEvent(
      type: type,
      message: message,
      timestamp: DateTime.now(),
      userId: userId,
      deviceId: deviceId,
    );

    // Add to event stream if instance exists
    final instance = _instance;
    if (instance._isInitialized && !instance._authEventController.isClosed) {
      instance._authEventController.add(event);
    }

    // Also log to console in debug mode
    if (kDebugMode) {
      print('[AUTH EVENT] ${type.toString()}: $message');
    }
  }

  /// Log authentication event (instance method)
  void _logAuthEvent(AuthEventType type, String message) {
    final event = AuthEvent(
      type: type,
      message: message,
      timestamp: DateTime.now(),
      userId: currentUser?.id,
      deviceId: '', // Will be set by device ID getter
    );

    if (!_authEventController.isClosed) {
      _authEventController.add(event);
    }

    // Also log to console in debug mode
    if (kDebugMode) {
      print('[AUTH EVENT] ${type.toString()}: $message');
    }
  }

  /// Update user activity
  Future<void> updateUserActivity() async {
    try {
      final sessionBox = Hive.box(_sessionBoxName);
      final sessionData = sessionBox.get(_currentSessionKey);

      if (sessionData != null && sessionData is Map) {
        final session = AuthSession.fromJson(Map<String, dynamic>.from(sessionData));
        session.lastActivity = DateTime.now();
        await _saveSession(session);
      }
    } catch (e) {
      _logAuthEvent(AuthEventType.error, 'Failed to update user activity: $e');
    }
  }

  /// Check if session is valid
  bool isSessionValid() {
    try {
      final sessionBox = Hive.box(_sessionBoxName);
      final sessionData = sessionBox.get(_currentSessionKey);

      if (sessionData == null || sessionData is! Map) {
        return false;
      }

      final session = AuthSession.fromJson(Map<String, dynamic>.from(sessionData));
      return session.isValid;
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _authStateController.close();
    _authEventController.close();
    _connectivitySubscription.cancel();
  }
}

/// Authentication State
enum AuthState {
  uninitialized,
  unauthenticated,
  authenticating,
  authenticated,
  offlineAuthenticated,
  connectivityRestored,
  error,
}

/// Authentication Result
enum AuthResult {
  success,
  failure,
  requiresVerification,
}

/// Authentication Event Types
enum AuthEventType {
  serviceInitialized,
  loginAttempt,
  loginSuccessful,
  loginFailed,
  offlineLoginSuccessful,
  registrationAttempt,
  registrationSuccessful,
  registrationFailed,
  logoutSuccessful,
  sessionRestored,
  sessionExpired,
  connectivityChanged,
  biometricAuthAttempt,
  biometricAuthSuccessful,
  biometricAuthFailed,
  mfaRequired,
  mfaVerified,
  mfaEnabled,
  mfaDisabled,
  mfaVerificationFailed,
  mfaBackupCodesRegenerated,
  passwordResetRequested,
  passwordResetSuccessful,
  emailVerificationSent,
  emailVerified,
  socialAuthAttempt,
  socialAuthSuccessful,
  socialAuthFailed,
  socialAccountLinked,
  socialAccountLinkFailed,
  socialAccountUnlinked,
  syncEvent,
  adminAction,
  error,
}

/// Authentication Event
class AuthEvent {
  final AuthEventType type;
  final String message;
  final DateTime timestamp;
  final String? userId;
  final String? deviceId;
  final Map<String, dynamic>? metadata;

  AuthEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.userId,
    this.deviceId,
    this.metadata,
  });
}

/// Authentication Session
class AuthSession {
  final String userId;
  final String deviceId;
  final DateTime loginTime;
  DateTime lastActivity;
  final bool isOnline;
  final Duration sessionTimeout;

  AuthSession({
    required this.userId,
    required this.deviceId,
    required this.loginTime,
    required this.lastActivity,
    required this.isOnline,
    this.sessionTimeout = const Duration(hours: 24),
  });

  bool get isValid {
    final now = DateTime.now();
    final timeSinceLastActivity = now.difference(lastActivity);
    return timeSinceLastActivity < sessionTimeout;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'deviceId': deviceId,
      'loginTime': loginTime.toIso8601String(),
      'lastActivity': lastActivity.toIso8601String(),
      'isOnline': isOnline,
      'sessionTimeoutHours': sessionTimeout.inHours,
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['userId'],
      deviceId: json['deviceId'],
      loginTime: DateTime.parse(json['loginTime']),
      lastActivity: DateTime.parse(json['lastActivity']),
      isOnline: json['isOnline'] ?? false,
      sessionTimeout: Duration(hours: json['sessionTimeoutHours'] ?? 24),
    );
  }
}