import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../models/user_role.dart' as user_role;
import '../services/firebase_service.dart';
import '../services/local_auth_service.dart';
import 'home_screen.dart';

class AdminSetupScreen extends StatefulWidget {
  const AdminSetupScreen({super.key});

  @override
  State<AdminSetupScreen> createState() => _AdminSetupScreenState();
}

class _AdminSetupScreenState extends State<AdminSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _schoolNameController = TextEditingController();
  final _adminNameController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _schoolNameController.text = 'Smart School Assistant';
  }

  Future<void> _createAdminAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final schoolName = _schoolNameController.text.trim();
      final adminName = _adminNameController.text.trim();

      // Create Firebase user
      final userCredential =
          await FirebaseService.auth.createUserWithEmailAndPassword(
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

      // Register admin for local authentication
      await LocalAuthService.registerLocalUser(email, password, adminUser);

      // Set current user for access control
      final accessUser = user_role.User(
        id: adminUser.id,
        email: adminUser.email,
        displayName: adminUser.displayName ?? '',
        role: user_role.UserRole.admin,
        permissions:
            user_role.User.getDefaultPermissions(user_role.UserRole.admin),
        createdAt: adminUser.createdAt,
        lastLoginAt: adminUser.lastLoginAt,
      );
      user_role.AccessControlManager.setCurrentUser(accessUser);

      // Mark admin setup as complete and store admin email
      final prefs = await Hive.openBox('preferences');
      await prefs.put('adminSetupComplete', true);

      // Store admin email for future recognition
      final adminEmails = prefs.get('admin_emails', defaultValue: <String>[]);
      if (adminEmails is List<String> && !adminEmails.contains(email)) {
        adminEmails.add(email);
        await prefs.put('admin_emails', adminEmails);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
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
                        Icons.admin_panel_settings,
                        size: 64,
                        color: Colors.indigo,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Welcome to Smart School Assistant',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Setup your admin account to get started',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // School Name Field
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

                      // Admin Name Field
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

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Admin Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter admin email';
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
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirm Password Field
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

                      // Create Admin Account Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _createAdminAccount,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Create Admin Account'),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info Text
                      const Text(
                        'This will create your first administrator account. You can create additional accounts later.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
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
