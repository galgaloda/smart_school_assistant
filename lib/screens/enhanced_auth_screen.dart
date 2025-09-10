import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models.dart';
import '../models/user_role.dart' as user_role;
import '../services/firebase_service.dart';
import '../services/local_auth_service.dart';
import '../services/mfa_service.dart';
import '../services/social_auth_service.dart';
import '../services/auth_event_logger.dart';
import '../services/user_sync_service.dart';
import '../widgets/user_profile_header.dart';
import 'home_screen.dart';
import '../main.dart';

/// Enhanced Combined Authentication Screen
/// Features comprehensive authentication with MFA, social auth, and advanced UI
class EnhancedAuthScreen extends StatefulWidget {
  const EnhancedAuthScreen({super.key});

  @override
  State<EnhancedAuthScreen> createState() => _EnhancedAuthScreenState();
}

class _EnhancedAuthScreenState extends State<EnhancedAuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _adminNameController = TextEditingController();
  final _mfaCodeController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _isOffline = false;
  bool _showMFAPrompt = false;
  final bool _showSocialAuth = true;
  String? _errorMessage;
  String? _successMessage;
  bool _adminSetupComplete = false;
  String? _pendingMFAUserId;
  MFAFactor? _selectedMFAFactor;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _setupAnimations();
    _setupConnectivityMonitoring();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  Future<void> _setupConnectivityMonitoring() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((result) => result != ConnectivityResult.none);
      if (mounted) {
        setState(() {
          _isOffline = !isOnline;
        });
      }
    });

    final initialConnectivity = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = initialConnectivity.any((result) => result == ConnectivityResult.none);
    });
  }

  Future<void> _initializeScreen() async {
    await _checkAdminSetup();
    await _checkExistingUser();
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
      final currentUser = FirebaseService.currentUser;
      if (currentUser != null) {
        try {
          final usersBox = Hive.box<User>('users');
          final localUser = usersBox.get(currentUser.uid);

          if (localUser != null) {
            final role = _mapStringToUserRole(localUser.role);
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
      _successMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Log authentication attempt
      await AuthEventLogger.logEvent(
        AuthEventType.loginAttempt,
        'Authentication attempt for: $email',
        severity: AuthEventSeverity.info,
      );

      if (_isOffline) {
        await _handleOfflineAuthentication(email, password);
      } else {
        await _handleOnlineAuthentication(email, password);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });

      await AuthEventLogger.logEvent(
        AuthEventType.loginFailed,
        'Authentication failed: $e',
        severity: AuthEventSeverity.warning,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleOfflineAuthentication(String email, String password) async {
    final localUser = await LocalAuthService.authenticateLocalUser(email, password);

    if (localUser != null) {
      // Check if MFA is enabled for this user
      final mfaEnabled = await MFAService.isMFAEnabled(localUser.id);

      if (mfaEnabled) {
        setState(() {
          _showMFAPrompt = true;
          _pendingMFAUserId = localUser.id;
        });
        return;
      }

      await _completeAuthentication(localUser);
    } else {
      throw Exception('Invalid credentials. Please check your email and password.');
    }
  }

  Future<void> _handleOnlineAuthentication(String email, String password) async {
    if (_adminSetupComplete) {
      await _loginOnline(email, password);
    } else {
      await _setupAdminAccount(email, password);
    }
  }

  Future<void> _loginOnline(String email, String password) async {
    final userCredential = await FirebaseService.auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final usersBox = Hive.box<User>('users');
    User? localUser = usersBox.get(userCredential.user!.uid);

    if (localUser == null) {
      // Create local user from Firebase data
      localUser = User(
        id: userCredential.user!.uid,
        email: email,
        displayName: userCredential.user!.displayName ?? email.split('@')[0],
        role: 'student',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      await usersBox.put(userCredential.user!.uid, localUser);
    }

    // Check if MFA is enabled
    final mfaEnabled = await MFAService.isMFAEnabled(localUser.id);

    if (mfaEnabled) {
      setState(() {
        _showMFAPrompt = true;
        _pendingMFAUserId = localUser!.id;
      });
      return;
    }

    await _completeAuthentication(localUser);
  }

  Future<void> _verifyMFA() async {
    if (_pendingMFAUserId == null || _selectedMFAFactor == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await MFAService.verifyMFACode(
        _pendingMFAUserId!,
        _mfaCodeController.text.trim(),
        _selectedMFAFactor!,
      );

      if (result.success) {
        // Get the user and complete authentication
        final usersBox = Hive.box<User>('users');
        final user = usersBox.get(_pendingMFAUserId!);

        if (user != null) {
          await _completeAuthentication(user);
        } else {
          throw Exception('User data not found');
        }
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Invalid MFA code';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'MFA verification failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _completeAuthentication(User user) async {
    // Update last login time
    user.lastLoginAt = DateTime.now();
    final usersBox = Hive.box<User>('users');
    await usersBox.put(user.id, user);

    // Set current user for access control
    final role = _mapStringToUserRole(user.role);
    final accessUser = user_role.User(
      id: user.id,
      email: user.email,
      displayName: user.displayName ?? '',
      role: role,
      permissions: user_role.User.getDefaultPermissions(role),
      createdAt: user.createdAt,
      lastLoginAt: user.lastLoginAt,
    );
    user_role.AccessControlManager.setCurrentUser(accessUser);

    // Log successful authentication
    await AuthEventLogger.logEvent(
      AuthEventType.loginSuccessful,
      'Authentication successful for: ${user.email}',
      userId: user.id,
      severity: AuthEventSeverity.info,
    );

    setState(() {
      _successMessage = 'Welcome back, ${user.displayName ?? user.email}!';
    });

    // Navigate to home after a brief delay
    Future.delayed(const Duration(seconds: 1), () {
      _navigateToHome();
    });
  }

  Future<void> _setupAdminAccount(String email, String password) async {
    final schoolName = _schoolNameController.text.trim();
    final adminName = _adminNameController.text.trim();

    if (schoolName.isEmpty || adminName.isEmpty) {
      throw Exception('Please fill in all required fields.');
    }

    final userCredential = await FirebaseService.auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await userCredential.user?.updateDisplayName(adminName);

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

    final usersBox = Hive.box<User>('users');
    await usersBox.put(userCredential.user!.uid, adminUser);

    await LocalAuthService.registerLocalUser(email, password, adminUser);

    // Save to Firestore
    await FirebaseService.firestore.collection('users').doc(adminUser.id).set({
      'email': adminUser.email,
      'displayName': adminUser.displayName,
      'role': adminUser.role,
      'createdAt': Timestamp.fromDate(adminUser.createdAt),
      'lastLoginAt': Timestamp.fromDate(adminUser.lastLoginAt ?? DateTime.now()),
      'isActive': adminUser.isActive,
      'schoolName': adminUser.schoolName,
      'deviceId': await _getDeviceId(),
      'lastDeviceSync': Timestamp.fromDate(DateTime.now()),
    });

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

    final prefs = await Hive.openBox('preferences');
    await prefs.put('adminSetupComplete', true);

    await AuthEventLogger.logEvent(
      AuthEventType.registrationSuccessful,
      'Admin account setup completed for: $email',
      userId: adminUser.id,
      severity: AuthEventSeverity.info,
    );

    _navigateToHome();
  }

  Future<void> _handleSocialAuth(SocialProvider provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      SocialAuthResult result;

      switch (provider) {
        case SocialProvider.google:
          result = await SocialAuthService.signInWithGoogle();
          break;
        case SocialProvider.facebook:
          result = await SocialAuthService.signInWithFacebook();
          break;
        case SocialProvider.apple:
          result = await SocialAuthService.signInWithApple();
          break;
        default:
          throw Exception('Unsupported social provider');
      }

      if (result.success && result.user != null) {
        await _completeAuthentication(result.user!);
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Social authentication failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Social authentication failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _getDeviceId() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return 'device_${timestamp.substring(timestamp.length - 8)}';
  }

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

  void _navigateToHome() {
    if (appKey.currentState != null) {
      (appKey.currentState as SmartSchoolAppState).refreshAdminSetupStatus();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _errorMessage = null;
      _successMessage = null;
      _showMFAPrompt = false;
      _pendingMFAUserId = null;
      _selectedMFAFactor = null;
      _mfaCodeController.clear();
    });
  }

  void _showMFAOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select MFA Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Authenticator App (TOTP)'),
              subtitle: const Text('Use Google Authenticator or similar'),
              onTap: () {
                setState(() {
                  _selectedMFAFactor = MFAFactor.totp;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.sms),
              title: const Text('SMS Code'),
              subtitle: const Text('Receive code via SMS'),
              onTap: () {
                setState(() {
                  _selectedMFAFactor = MFAFactor.sms;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Code'),
              subtitle: const Text('Receive code via email'),
              onTap: () {
                setState(() {
                  _selectedMFAFactor = MFAFactor.email;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _isLogin
                ? [Colors.indigo.shade900, Colors.blue.shade900]
                : [Colors.teal.shade900, Colors.green.shade900],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Header with sync status
                    if (_adminSetupComplete)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: CompactUserProfile(
                          onTap: () {
                            // Show user menu
                            _showUserMenu();
                          },
                        ),
                      ),

                    // Main Auth Card
                    Card(
                      elevation: 12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: _showMFAPrompt
                            ? _buildMFAPrompt()
                            : _buildAuthForm(),
                      ),
                    ),

                    // Social Auth Buttons
                    if (_showSocialAuth && !_showMFAPrompt && _adminSetupComplete)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: _buildSocialAuthButtons(),
                      ),

                    // Offline indicator
                    if (_isOffline)
                      Container(
                        margin: const EdgeInsets.only(top: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You are offline. Some features may be limited.',
                                style: TextStyle(color: Colors.orange[700]),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo and Title
          Icon(
            _adminSetupComplete ? Icons.login : Icons.admin_panel_settings,
            size: 64,
            color: _isLogin ? Colors.indigo : Colors.teal,
          ),
          const SizedBox(height: 16),
          Text(
            _adminSetupComplete
                ? (_isLogin ? 'Welcome Back' : 'Create Account')
                : 'Setup Smart School Assistant',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _isLogin ? Colors.indigo : Colors.teal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _adminSetupComplete
                ? (_isLogin ? 'Sign in to your account' : 'Join our school community')
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
              decoration: InputDecoration(
                labelText: 'School Name',
                prefixIcon: const Icon(Icons.school),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
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
              decoration: InputDecoration(
                labelText: 'Administrator Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
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
            decoration: InputDecoration(
              labelText: 'Email',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
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
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
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
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
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
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          // Success Message
          if (_successMessage != null)
            Container(
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _successMessage!,
                      style: const TextStyle(color: Colors.green),
                    ),
                  ),
                ],
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
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: _isLogin ? Colors.indigo : Colors.teal,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _adminSetupComplete
                          ? (_isLogin ? 'Sign In' : 'Create Account')
                          : 'Create Admin Account',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
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
                style: TextStyle(
                  color: _isLogin ? Colors.indigo : Colors.teal,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMFAPrompt() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.security,
          size: 64,
          color: Colors.blue,
        ),
        const SizedBox(height: 16),
        const Text(
          'Two-Factor Authentication',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your verification code',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // MFA Code Input
        TextFormField(
          controller: _mfaCodeController,
          decoration: InputDecoration(
            labelText: 'Verification Code',
            prefixIcon: const Icon(Icons.lock),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter verification code';
            }
            if (value.length != 6) {
              return 'Code must be 6 digits';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // MFA Method Selector
        if (_selectedMFAFactor == null)
          ElevatedButton.icon(
            onPressed: _showMFAOptions,
            icon: const Icon(Icons.security),
            label: const Text('Select Verification Method'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _getMFAFactorIcon(_selectedMFAFactor!),
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  _getMFAFactorName(_selectedMFAFactor!),
                  style: const TextStyle(color: Colors.blue),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _selectedMFAFactor = null),
                  icon: const Icon(Icons.edit, size: 16),
                  color: Colors.blue,
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),

        // Verify Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyMFA,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.blue,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Verify',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),

        const SizedBox(height: 16),

        // Back to login
        TextButton(
          onPressed: () {
            setState(() {
              _showMFAPrompt = false;
              _pendingMFAUserId = null;
              _selectedMFAFactor = null;
              _mfaCodeController.clear();
            });
          },
          child: const Text('Back to Login'),
        ),
      ],
    );
  }

  Widget _buildSocialAuthButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey[400])),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Or continue with',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey[400])),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google Sign In
            if (SocialAuthService.isProviderAvailable(SocialProvider.google))
              _buildSocialButton(
                icon: 'assets/icons/google.png', // You'll need to add these assets
                label: 'Google',
                onPressed: () => _handleSocialAuth(SocialProvider.google),
                color: Colors.white,
                textColor: Colors.grey[700]!,
              ),

            const SizedBox(width: 12),

            // Facebook Sign In
            if (SocialAuthService.isProviderAvailable(SocialProvider.facebook))
              _buildSocialButton(
                icon: 'assets/icons/facebook.png',
                label: 'Facebook',
                onPressed: () => _handleSocialAuth(SocialProvider.facebook),
                color: const Color(0xFF1877F2),
                textColor: Colors.white,
              ),

            const SizedBox(width: 12),

            // Apple Sign In
            if (SocialAuthService.isProviderAvailable(SocialProvider.apple))
              _buildSocialButton(
                icon: 'assets/icons/apple.png',
                label: 'Apple',
                onPressed: () => _handleSocialAuth(SocialProvider.apple),
                color: Colors.black,
                textColor: Colors.white,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton({
    required String icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    required Color textColor,
  }) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : onPressed,
      icon: Icon(Icons.account_circle, color: textColor), // Placeholder for actual icons
      label: Text(label, style: TextStyle(color: textColor)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  IconData _getMFAFactorIcon(MFAFactor factor) {
    switch (factor) {
      case MFAFactor.totp:
        return Icons.security;
      case MFAFactor.sms:
        return Icons.sms;
      case MFAFactor.email:
        return Icons.email;
      case MFAFactor.backupCodes:
        return Icons.backup;
    }
  }

  String _getMFAFactorName(MFAFactor factor) {
    switch (factor) {
      case MFAFactor.totp:
        return 'Authenticator App';
      case MFAFactor.sms:
        return 'SMS Code';
      case MFAFactor.email:
        return 'Email Code';
      case MFAFactor.backupCodes:
        return 'Backup Code';
    }
  }

  void _showUserMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Account Options',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Sync Data'),
              subtitle: const Text('Synchronize across devices'),
              onTap: () async {
                Navigator.pop(context);
                await _forceSync();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign Out'),
              onTap: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _forceSync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await UserSyncService.forceSync();
      if (result.success) {
        setState(() {
          _successMessage = 'Data synchronized successfully';
        });
      } else {
        setState(() {
          _errorMessage = result.error ?? 'Sync failed';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Sync failed: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseService.signOut();
      user_role.AccessControlManager.setCurrentUser(null);

      setState(() {
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _errorMessage = null;
        _successMessage = null;
      });

      await AuthEventLogger.logEvent(
        AuthEventType.logoutSuccessful,
        'User signed out successfully',
        severity: AuthEventSeverity.info,
      );

    } catch (e) {
      setState(() {
        _errorMessage = 'Sign out failed: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _connectivitySubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _schoolNameController.dispose();
    _adminNameController.dispose();
    _mfaCodeController.dispose();
    super.dispose();
  }
}