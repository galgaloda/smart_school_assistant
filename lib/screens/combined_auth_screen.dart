import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';
import '../models/user_role.dart' as user_role;
import '../services/firebase_service.dart';
import '../services/local_auth_service.dart';
import 'home_screen.dart';
import '../main.dart';

class CombinedAuthScreen extends StatefulWidget {
  const CombinedAuthScreen({super.key});

  @override
  State<CombinedAuthScreen> createState() => _CombinedAuthScreenState();
}

class _CombinedAuthScreenState extends State<CombinedAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _adminNameController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isOffline = false;
  String? _errorMessage;
  bool _adminSetupComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _checkConnectivity();
  }

  Future<void> _initializeScreen() async {
    await _checkAdminSetup();
    await _checkExistingUser();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult.any((result) => result == ConnectivityResult.none);
    });
  }

  Future<void> _checkAdminSetup() async {
    try {
      final prefs = await Hive.openBox('preferences');
      final adminSetupComplete = prefs.get('adminSetupComplete', defaultValue: false);
      setState(() {
        _adminSetupComplete = adminSetupComplete;
      });
    } catch (e) {
      setState(() {
        _adminSetupComplete = false;
      });
    }
  }

  Future<void> _checkExistingUser() async {
    if (_adminSetupComplete) {
      // Check if user is already logged in locally
      final usersBox = Hive.box<User>('users');
      final currentUser = FirebaseService.currentUser;

      if (currentUser != null) {
        try {
          final localUser = usersBox.values.firstWhere(
            (user) => user.id == currentUser.uid,
          );

          if (localUser.id.isNotEmpty) {
            // Set current user for access control
            final role = localUser.role == 'admin' ? user_role.UserRole.admin :
                         localUser.role == 'teacher' ? user_role.UserRole.teacher :
                         localUser.role == 'student' ? user_role.UserRole.student :
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
            _navigateToHome();
          }
        } catch (e) {
          // User not found locally, continue to login screen
        }
      }
    }
  }

  Future<void> _authenticate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // OFFLINE-FIRST APPROACH: Always try local authentication first
      final localUser = await _authenticateLocally(email, password);

      if (localUser != null) {
        // Local authentication successful
        await _handleSuccessfulLocalAuth(localUser);

        // Try to sync with online if internet available
        if (!_isOffline) {
          await _syncWithOnline(localUser);
        }

        _navigateToHome();
      } else {
        // Local authentication failed
        if (_isOffline) {
          throw Exception('Invalid credentials. Please check your email and password.');
        } else {
          // Online mode: try to authenticate with server or create account
          if (_adminSetupComplete) {
            await _handleOnlineAuth(email, password);
          } else {
            await _setupAdminAccount(email, password);
          }
        }
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



  Future<User?> _authenticateLocally(String email, String password) async {
    // Use the existing LocalAuthService for authentication
    return await LocalAuthService.authenticateLocalUser(email, password);
  }

  Future<void> _handleSuccessfulLocalAuth(User localUser) async {
    // Update last login time
    localUser.lastLoginAt = DateTime.now();
    final usersBox = Hive.box<User>('users');
    await usersBox.put(localUser.id, localUser);

    // Set current user for access control
    final role = localUser.role == 'admin' ? user_role.UserRole.admin :
                  localUser.role == 'teacher' ? user_role.UserRole.teacher :
                  localUser.role == 'student' ? user_role.UserRole.student :
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
  }

  Future<void> _syncWithOnline(User localUser) async {
    try {
      // Check if user is already authenticated with Firebase
      final currentFirebaseUser = FirebaseService.currentUser;

      if (currentFirebaseUser != null && currentFirebaseUser.uid == localUser.id) {
        // User is already authenticated, sync latest data from Firestore
        await _syncUserFromFirestore(currentFirebaseUser);
        print('Successfully synced user data from Firestore');
      } else {
        // User not authenticated with Firebase, try to sync without re-authentication
        // This handles cross-device scenarios where user data exists in Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(localUser.id)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          final usersBox = Hive.box<User>('users');

          final syncedUser = User(
            id: localUser.id,
            email: userData['email'] ?? localUser.email,
            displayName: userData['displayName'] ?? localUser.displayName,
            role: userData['role'] ?? localUser.role,
            createdAt: (userData['createdAt'] as Timestamp?)?.toDate() ?? localUser.createdAt,
            lastLoginAt: DateTime.now(),
            isActive: userData['isActive'] ?? localUser.isActive,
            schoolName: userData['schoolName'] ?? localUser.schoolName,
            schoolAddress: userData['schoolAddress'] ?? localUser.schoolAddress,
            schoolPhone: userData['schoolPhone'] ?? localUser.schoolPhone,
          );

          await usersBox.put(localUser.id, syncedUser);
          print('Successfully synced user data from Firestore without authentication');
        }
      }
    } catch (e) {
      // Online sync failed, but local auth was successful
      // Continue with local data
      print('Online sync failed, using local data: $e');
    }
  }

  Future<void> _handleOnlineAuth(String email, String password) async {
    try {
      // Try to login online first
      final userCredential = await FirebaseService.auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Sync user data from Firestore
      await _syncUserFromFirestore(userCredential.user!);

      // Set current user for access control
      final usersBox = Hive.box<User>('users');
      final localUser = usersBox.get(userCredential.user!.uid)!;

      final role = localUser.role == 'admin' ? user_role.UserRole.admin :
                    localUser.role == 'teacher' ? user_role.UserRole.teacher :
                    localUser.role == 'student' ? user_role.UserRole.student :
                    user_role.UserRole.staff;
      final accessUser = user_role.User(
        id: localUser.id,
        email: localUser.email,
        displayName: localUser.displayName ?? '',
        role: role,
        permissions: user_role.User.getDefaultPermissions(role),
        createdAt: localUser.createdAt,
        lastLoginAt: DateTime.now(),
      );
      user_role.AccessControlManager.setCurrentUser(accessUser);

      _navigateToHome();
    } catch (e) {
      // Online login failed, try to create new account
      await _registerNewUser(email, password);
    }
  }

  Future<void> _registerNewUser(String email, String password) async {
    final userCredential = await FirebaseService.auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Create user in local database
    final usersBox = Hive.box<User>('users');
    final newUser = User(
      id: userCredential.user!.uid,
      email: email,
      displayName: userCredential.user!.displayName ?? email.split('@')[0],
      role: 'student', // Default role for new users
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isActive: true,
    );

    await usersBox.put(userCredential.user!.uid, newUser);

    // Register for local authentication
    await LocalAuthService.registerLocalUser(email, password, newUser);

    // Save to Firestore
    await _saveUserToFirestore(newUser);

    // Set current user for access control
    final accessUser = user_role.User(
      id: newUser.id,
      email: newUser.email,
      displayName: newUser.displayName ?? '',
      role: user_role.UserRole.student,
      permissions: user_role.User.getDefaultPermissions(user_role.UserRole.student),
      createdAt: newUser.createdAt,
      lastLoginAt: newUser.lastLoginAt,
    );
    user_role.AccessControlManager.setCurrentUser(accessUser);

    _navigateToHome();
  }


  Future<void> _setupAdminAccount(String email, String password) async {
    final schoolName = _schoolNameController.text.trim();
    final adminName = _adminNameController.text.trim();

    if (schoolName.isEmpty || adminName.isEmpty) {
      throw Exception('Please fill in all required fields.');
    }

    // Create Firebase user
    final userCredential = await FirebaseService.auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update display name
    await userCredential.user?.updateDisplayName(adminName);

    // Create admin user in local database
    final usersBox = Hive.box<User>('users');
    final adminUser = User(
      id: userCredential.user!.uid,
      email: email,
      displayName: adminName,
      role: 'admin',
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
      isActive: true,
      schoolName: schoolName,
    );

    await usersBox.put(userCredential.user!.uid, adminUser);

    // Save to Firestore for cross-device recognition
    await _saveUserToFirestore(adminUser);

    // Set current user for access control
    final accessUser = user_role.User(
      id: adminUser.id,
      email: adminUser.email,
      displayName: adminUser.displayName ?? '',
      role: user_role.UserRole.admin,
      permissions: user_role.User.getDefaultPermissions(user_role.UserRole.admin),
      createdAt: adminUser.createdAt,
      lastLoginAt: adminUser.lastLoginAt,
    );
    user_role.AccessControlManager.setCurrentUser(accessUser);

    // Mark admin setup as complete
    final prefs = await Hive.openBox('preferences');
    await prefs.put('adminSetupComplete', true);

    _navigateToHome();
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
    } catch (e) {
      print('Error saving user to Firestore: $e');
    }
  }

  void _navigateToHome() {
    // Refresh the main app state to check admin setup status
    if (appKey.currentState != null) {
      (appKey.currentState as SmartSchoolAppState).refreshAdminSetupStatus();
    }

    // Navigate to home screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
    });
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
                      Text(
                        _adminSetupComplete
                            ? 'Welcome Back'
                            : 'Setup Smart School Assistant',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _adminSetupComplete
                            ? 'Sign in to your account'
                            : 'Create your administrator account',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // School Name Field (only for admin setup)
                      if (!_adminSetupComplete) ...[
                        TextFormField(
                          controller: _schoolNameController,
                          decoration: const InputDecoration(
                            labelText: 'School Name',
                            prefixIcon: Icon(Icons.school),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your school name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Admin Name Field (only for admin setup)
                        TextFormField(
                          controller: _adminNameController,
                          decoration: const InputDecoration(
                            labelText: 'Administrator Name',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter administrator name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

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

                      // Confirm Password Field (only for admin setup)
                      if (!_adminSetupComplete)
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

                      // Authenticate Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _authenticate,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : Text(_adminSetupComplete ? 'Sign In' : 'Create Admin Account'),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Toggle between modes (only if admin setup is complete)
                      if (_adminSetupComplete)
                        TextButton(
                          onPressed: _toggleMode,
                          child: Text(
                            _isLogin
                                ? 'Need to create an account?'
                                : 'Already have an account?',
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
    _schoolNameController.dispose();
    _adminNameController.dispose();
    super.dispose();
  }
}