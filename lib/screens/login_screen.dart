import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models.dart';
import '../models/user_role.dart' as user_role;
import '../services/firebase_service.dart';
import '../services/local_auth_service.dart';
import 'home_screen.dart';
import 'admin_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isOffline = false;
  String? _errorMessage;
  firebase_auth.User? _currentUser;
  bool _adminSetupComplete = false;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _checkExistingUser();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult == ConnectivityResult.none;
    });
  }

  Future<void> _checkExistingUser() async {
    // Check if admin setup is complete first
    final prefs = await Hive.openBox('preferences');
    final adminSetupComplete = prefs.get('adminSetupComplete', defaultValue: false);

    // Store admin setup status but don't redirect immediately
    setState(() {
      _adminSetupComplete = adminSetupComplete;
    });

    // Check if user is already logged in locally
    final usersBox = Hive.box<User>('users');
    final currentUser = FirebaseService.currentUser;
    print('Checking existing user - Firebase currentUser: ${currentUser?.uid}');

    if (currentUser != null) {
      try {
        final localUser = usersBox.values.firstWhere(
          (user) => user.id == currentUser.uid,
        );

        if (localUser.id.isNotEmpty) {
          setState(() {
            _currentUser = currentUser;
          });
          // Set current user for access control
          print('Setting current user for existing user check');
          final role = localUser.role == 'admin' ? user_role.UserRole.admin :
                       localUser.role == 'teacher' ? user_role.UserRole.teacher :
                       localUser.role == 'student' ? user_role.UserRole.student :
                       user_role.UserRole.staff;
          print('Role: $role');
          final accessUser = user_role.User(
            id: localUser.id,
            email: localUser.email,
            displayName: localUser.displayName ?? '',
            role: role,
            permissions: user_role.User.getDefaultPermissions(role),
            createdAt: localUser.createdAt,
            lastLoginAt: localUser.lastLoginAt,
          );
          print('Access user created: $accessUser');
          print('User permissions: ${accessUser.permissions}');
          user_role.AccessControlManager.setCurrentUser(accessUser);
          print('Current user set in AccessControlManager');
          print('Verification - Current user after setting: ${user_role.AccessControlManager.getCurrentUser()}');
          _navigateToHome();
        }
      } catch (e) {
        // User not found locally, but Firebase user exists
        // This can happen when user logs in on a new device or after logout
        // Create local user data automatically
        print('Firebase user exists but no local user found. Creating local user data...');

        try {
          // Determine role - check if this is the admin user
          String userRole = await _determineUserRole(currentUser);

          // Create local user
          final localUser = User(
            id: currentUser.uid,
            email: currentUser.email ?? '',
            displayName: currentUser.displayName,
            photoUrl: currentUser.photoURL,
            role: userRole,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
            isActive: true,
          );

          await usersBox.put(currentUser.uid, localUser);

          // Set current user for access control
          final role = userRole == 'admin' ? user_role.UserRole.admin :
                       userRole == 'teacher' ? user_role.UserRole.teacher :
                       userRole == 'student' ? user_role.UserRole.student :
                       user_role.UserRole.staff;

          final accessUser = user_role.User(
            id: localUser.id,
            email: localUser.email,
            displayName: localUser.displayName ?? '',
            role: role,
            permissions: user_role.User.getDefaultPermissions(role),
            createdAt: localUser.createdAt,
            lastLoginAt: localUser.lastLoginAt,
          );

          user_role.AccessControlManager.setCurrentUser(accessUser);
          print('Local user data created and user set successfully');

          // Show success message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Welcome back! Your account has been restored.'),
                backgroundColor: Colors.green,
              ),
            );
          }

          _navigateToHome();
        } catch (createError) {
          print('Error creating local user data: $createError');
          // Continue to login screen if we can't create local user
        }
      }
    } else {
      print('No Firebase user found, will show login screen');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isOffline) {
        // Offline login - check local database
        await _loginOffline(email, password);
      } else {
        // Online login - use Firebase Auth
        await _loginOnline(email, password);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loginOnline(String email, String password) async {
    print('[LOGIN] Starting online login for email: $email');

    final userCredential = await FirebaseService.auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    print('[LOGIN] Firebase authentication successful for user: ${userCredential.user!.uid}');

    // Sync user data from Firestore first
    await _syncUserFromFirestore(userCredential.user!);

    // Check if user already exists locally
    final usersBox = Hive.box<User>('users');
    User? existingUser;

    try {
      existingUser = usersBox.values.firstWhere(
        (user) => user.id == userCredential.user!.uid,
      );
      print('[LOGIN] Found existing local user with role: ${existingUser.role}');
    } catch (e) {
      print('[LOGIN] No existing local user found, will create new one');
    }

    User localUser;
    if (existingUser != null) {
      // Update existing user's last login time
      existingUser.lastLoginAt = DateTime.now();
      await usersBox.put(existingUser.id, existingUser);
      localUser = existingUser;
      print('[LOGIN] Updated existing user last login time');
    } else {
      // Determine user role for new user
      final userRole = await _determineUserRole(userCredential.user!);
      print('[LOGIN] Determined role for new user: $userRole');

      // Create new local user
      localUser = User(
        id: userCredential.user!.uid,
        email: email,
        displayName: userCredential.user!.displayName ?? email.split('@')[0],
        role: userRole,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );

      await usersBox.put(userCredential.user!.uid, localUser);
      print('[LOGIN] Created new local user with role: $userRole');
    }

    // Register for local authentication
    await LocalAuthService.registerLocalUser(email, password, localUser);
    print('[LOGIN] Registered user for local authentication');

    // Save/update user to Firestore for cross-device sync
    await _saveUserToFirestore(localUser);
    print('[LOGIN] User data saved to Firestore for cross-device sync');

    // Set current user for access control
    print('[LOGIN] Setting current user for access control');
    final role = localUser.role == 'admin' ? user_role.UserRole.admin :
                  localUser.role == 'teacher' ? user_role.UserRole.teacher :
                  localUser.role == 'student' ? user_role.UserRole.student :
                  user_role.UserRole.staff;
    print('[LOGIN] Converting string role "${localUser.role}" to enum: $role');

    final accessUser = user_role.User(
      id: localUser.id,
      email: localUser.email,
      displayName: localUser.displayName ?? '',
      role: role,
      permissions: user_role.User.getDefaultPermissions(role),
      createdAt: localUser.createdAt,
      lastLoginAt: localUser.lastLoginAt,
    );

    print('[LOGIN] Access user created with role: ${accessUser.role}');
    print('[LOGIN] User permissions count: ${accessUser.permissions.length}');

    user_role.AccessControlManager.setCurrentUser(accessUser);
    print('[LOGIN] Current user set in AccessControlManager');

    // Verification
    final setUser = user_role.AccessControlManager.getCurrentUser();
    print('[LOGIN] Verification - Current user: ${setUser?.role}');
    print('[LOGIN] Verification - Has admin permission: ${user_role.AccessControlManager.canManageSystemSettings()}');

    _navigateToHome();
  }

  Future<void> _loginOffline(String email, String password) async {
    // Try local authentication first
    final authenticatedUser = await LocalAuthService.authenticateLocalUser(email, password);

    if (authenticatedUser != null) {
      // Local authentication successful
      // For offline login, we don't set Firebase user, just navigate to home
      // The app will work with local data only

      // Update last login time
      authenticatedUser.lastLoginAt = DateTime.now();
      await LocalAuthService.updateLocalUser(email, authenticatedUser);

      // Set current user for access control
      print('Setting current user for offline login');
      final role = authenticatedUser.role == 'admin' ? user_role.UserRole.admin :
                   authenticatedUser.role == 'teacher' ? user_role.UserRole.teacher :
                   authenticatedUser.role == 'student' ? user_role.UserRole.student :
                   user_role.UserRole.staff;
      print('Role: $role');
      final accessUser = user_role.User(
        id: authenticatedUser.id,
        email: authenticatedUser.email,
        displayName: authenticatedUser.displayName ?? '',
        role: role,
        permissions: user_role.User.getDefaultPermissions(role),
        createdAt: authenticatedUser.createdAt,
        lastLoginAt: authenticatedUser.lastLoginAt,
      );
      print('Access user created: $accessUser');
      print('User permissions: ${accessUser.permissions}');
      user_role.AccessControlManager.setCurrentUser(accessUser);
      print('Current user set in AccessControlManager');
      print('Verification - Current user after setting: ${user_role.AccessControlManager.getCurrentUser()}');

      _navigateToHome();
    } else {
      // Check if user exists locally but password is wrong
      final isRegistered = await LocalAuthService.isUserRegisteredLocally(email);
      if (isRegistered) {
        throw Exception('Invalid password. Please try again.');
      } else {
        throw Exception('User not found locally. Please connect to internet to login and sync your account.');
      }
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isOffline) {
        throw Exception('Registration requires internet connection.');
      }

      print('[REGISTER] Creating Firebase account for: $email');
      final userCredential = await FirebaseService.auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('[REGISTER] Firebase account created: ${userCredential.user!.uid}');

      // Determine user role
      final userRole = await _determineUserRole(userCredential.user!);
      print('[REGISTER] Determined role: $userRole');

      // Save user locally with determined role
      await _saveUserLocally(userCredential.user!, userRole);

      // Get the saved user
      final usersBox = Hive.box<User>('users');
      final localUser = usersBox.get(userCredential.user!.uid)!;
      print('[REGISTER] Retrieved local user with role: ${localUser.role}');

      // Set current user for access control
      final role = localUser.role == 'admin' ? user_role.UserRole.admin :
                    localUser.role == 'teacher' ? user_role.UserRole.teacher :
                    localUser.role == 'student' ? user_role.UserRole.student :
                    user_role.UserRole.staff;

      print('[REGISTER] Setting access control with role: $role');
      final accessUser = user_role.User(
        id: localUser.id,
        email: localUser.email,
        displayName: localUser.displayName ?? '',
        role: role,
        permissions: user_role.User.getDefaultPermissions(role),
        createdAt: localUser.createdAt,
        lastLoginAt: localUser.lastLoginAt,
      );

      user_role.AccessControlManager.setCurrentUser(accessUser);
      print('[REGISTER] Access control set successfully');

      _navigateToHome();
    } catch (e) {
      print('[REGISTER] Registration failed: $e');
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncUserFromFirestore(firebase_auth.User firebaseUser) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final usersBox = Hive.box<User>('users');

        final localUser = User(
          id: firebaseUser.uid,
          email: userData['email'] ?? firebaseUser.email ?? '',
          displayName: userData['displayName'] ?? firebaseUser.displayName,
          role: userData['role'] ?? 'student',
          createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          lastLoginAt: DateTime.now(),
          isActive: userData['isActive'] ?? true,
          schoolName: userData['schoolName'],
          schoolAddress: userData['schoolAddress'],
          schoolPhone: userData['schoolPhone'],
        );

        await usersBox.put(firebaseUser.uid, localUser);
        print('[SYNC] User data synced from Firestore');
      }
    } catch (e) {
      print('Error syncing user from Firestore: $e');
    }
  }

  Future<void> _saveUserToFirestore(User user) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.id).set({
        'email': user.email,
        'displayName': user.displayName,
        'role': user.role,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'lastLoginAt': Timestamp.fromDate(user.lastLoginAt ?? DateTime.now()),
        'isActive': user.isActive,
        'schoolName': user.schoolName,
        'schoolAddress': user.schoolAddress,
        'schoolPhone': user.schoolPhone,
        'deviceId': 'flutter_app_${DateTime.now().millisecondsSinceEpoch}',
        'lastDeviceSync': Timestamp.fromDate(DateTime.now()),
      });
      print('[SYNC] User data saved to Firestore for cross-device sync');
    } catch (e) {
      print('Error saving user to Firestore: $e');
    }
  }

  Future<void> _saveUserLocally(firebase_auth.User firebaseUser, String role) async {
    print('[SAVE_USER] Saving user locally: ${firebaseUser.uid}, role: $role');

    final usersBox = Hive.box<User>('users');

    // Check if user already exists
    User? existingUser;
    try {
      existingUser = usersBox.get(firebaseUser.uid);
      if (existingUser != null) {
        print('[SAVE_USER] User already exists with role: ${existingUser.role}');
        // Update last login time but preserve existing role
        existingUser.lastLoginAt = DateTime.now();
        await usersBox.put(firebaseUser.uid, existingUser);
        return;
      }
    } catch (e) {
      print('[SAVE_USER] Error checking existing user: $e');
    }

    final localUser = User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      role: role,
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isActive: true,
    );

    await usersBox.put(firebaseUser.uid, localUser);
    print('[SAVE_USER] User saved locally with role: $role');
  }

  Future<void> _saveUserLocallyOffline(User localUser) async {
    final usersBox = Hive.box<User>('users');

    final updatedUser = User(
      id: localUser.id,
      email: localUser.email,
      displayName: localUser.displayName,
      photoUrl: localUser.photoUrl,
      role: localUser.role,
      createdAt: localUser.createdAt,
      lastLoginAt: DateTime.now(),
      isActive: localUser.isActive,
      schoolName: localUser.schoolName,
      schoolAddress: localUser.schoolAddress,
      schoolPhone: localUser.schoolPhone,
    );

    await usersBox.put(localUser.id, updatedUser);
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<String> _determineUserRole(firebase_auth.User firebaseUser) async {
    print('[ROLE_DET] Determining role for user: ${firebaseUser.email}');

    final usersBox = Hive.box<User>('users');
    final existingUsers = usersBox.values.toList();
    final email = firebaseUser.email ?? '';

    // Check if user already exists in local storage
    try {
      final existingUser = usersBox.get(firebaseUser.uid);
      if (existingUser != null) {
        print('[ROLE_DET] User exists locally with role: ${existingUser.role}');
        return existingUser.role; // Return existing role to preserve it
      }
    } catch (e) {
      print('[ROLE_DET] Error checking existing user: $e');
    }

    // Check admin emails list first
    try {
      final prefs = await Hive.openBox('preferences');
      final adminEmails = prefs.get('admin_emails', defaultValue: <String>[]);
      if (adminEmails is List<String> && adminEmails.contains(email)) {
        print('[ROLE_DET] User found in admin emails list: $email');
        return 'admin';
      }
    } catch (e) {
      print('[ROLE_DET] Error checking admin emails: $e');
    }

    // If this is the first user ever, make them admin
    if (existingUsers.isEmpty) {
      print('[ROLE_DET] First user detected, assigning admin role');
      try {
        final prefs = await Hive.openBox('preferences');
        await prefs.put('admin_emails', [email]);
        print('[ROLE_DET] Admin email stored for future reference');
      } catch (e) {
        print('[ROLE_DET] Error storing admin email: $e');
      }
      return 'admin';
    }

    // If admin setup is not complete, allow student/teacher registration
    try {
      final prefs = await Hive.openBox('preferences');
      final adminSetupComplete = prefs.get('adminSetupComplete', defaultValue: false);
      if (!adminSetupComplete) {
        print('[ROLE_DET] Admin setup not complete, assigning student role for now');
        return 'student'; // Default to student, can be changed later by admin
      }
    } catch (e) {
      print('[ROLE_DET] Error checking admin setup: $e');
    }

    // Check if email contains admin keywords
    final emailLower = email.toLowerCase();
    if (emailLower.contains('admin') || emailLower.contains('administrator') ||
        emailLower.contains('superuser') || emailLower.contains('root')) {
      print('[ROLE_DET] Admin email pattern detected: $email');
      try {
        final prefs = await Hive.openBox('preferences');
        final adminEmails = prefs.get('admin_emails', defaultValue: <String>[]);
        if (adminEmails is List<String> && !adminEmails.contains(email)) {
          adminEmails.add(email);
          await prefs.put('admin_emails', adminEmails);
          print('[ROLE_DET] Admin email added to list');
        }
      } catch (e) {
        print('[ROLE_DET] Error updating admin emails: $e');
      }
      return 'admin';
    }

    // Check if this is an admin setup scenario
    try {
      final prefs = await Hive.openBox('preferences');
      final adminSetupComplete = prefs.get('adminSetupComplete', defaultValue: false);
      if (!adminSetupComplete && existingUsers.isEmpty) {
        print('[ROLE_DET] Admin setup not complete, assigning admin role');
        await prefs.put('admin_emails', [email]);
        return 'admin';
      }
    } catch (e) {
      print('[ROLE_DET] Error checking admin setup: $e');
    }

    print('[ROLE_DET] Assigning default student role to: $email');
    return 'student';
  }

  void _navigateToAdminSetup() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const AdminSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo, Colors.blue],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo and Title
                      const Icon(
                        Icons.school,
                        size: 64,
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Smart School Assistant',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          Text(
                            _isOffline ? 'Offline Mode' : 'Welcome Back',
                            style: TextStyle(
                              fontSize: 16,
                              color: _isOffline ? Colors.orange : Colors.grey,
                            ),
                          ),
                          if (!_adminSetupComplete)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                'Admin setup required for full functionality',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field (only for registration)
                      if (!_isLogin)
                        TextFormField(
                          controller: _confirmPasswordController,
                          decoration: const InputDecoration(
                            labelText: 'Confirm Password',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),

                      // Error Message
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Login/Register Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : (_isLogin ? _login : _register),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : Text(_isLogin ? 'Login' : 'Register'),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Toggle between Login/Register
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _isLogin = !_isLogin;
                            _errorMessage = null;
                          });
                        },
                        child: Text(
                          _isLogin
                              ? 'Don\'t have an account? Register'
                              : 'Already have an account? Login',
                        ),
                      ),

                      // Admin Setup Button (only show if admin setup is not complete)
                      if (!_adminSetupComplete)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: OutlinedButton.icon(
                            onPressed: _navigateToAdminSetup,
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text('Setup Administrator Account'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.indigo,
                              side: const BorderSide(color: Colors.indigo),
                            ),
                          ),
                        ),

                      // Offline indicator
                      if (_isOffline)
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Text(
                            'You are offline. Some features may be limited.',
                            style: TextStyle(color: Colors.orange, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}