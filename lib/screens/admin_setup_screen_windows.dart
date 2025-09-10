import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../models/user_role.dart' as user_role;
import '../services/local_auth_service.dart';
import 'home_screen.dart';

class AdminSetupScreenWindows extends StatefulWidget {
  const AdminSetupScreenWindows({super.key});

  @override
  State<AdminSetupScreenWindows> createState() => _AdminSetupScreenWindowsState();
}

class _AdminSetupScreenWindowsState extends State<AdminSetupScreenWindows> {
  final _formKey = GlobalKey<FormState>();
  final _schoolNameController = TextEditingController();
  final _adminNameController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _schoolNameController.text = 'Smart School Assistant';
    _adminNameController.text = 'Windows Admin';
  }

  Future<void> _createAdminAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final schoolName = _schoolNameController.text.trim();
      final adminName = _adminNameController.text.trim();
      const email = 'admin@windows.local';
      const defaultPassword = 'admin123'; // Default password for Windows version

      // Create admin user in local database
      final usersBox = Hive.box<User>('users');
      final adminUser = User(
        id: 'windows_admin_default',
        email: email,
        displayName: adminName,
        role: 'admin',
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        isActive: true,
        schoolName: schoolName,
      );

      await usersBox.put('windows_admin_default', adminUser);

      // Register admin for local authentication with default password
      await LocalAuthService.registerLocalUser(email, defaultPassword, adminUser);

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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Windows admin account created successfully!\nDefault password: $defaultPassword'),
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
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating admin account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                        Icons.school,
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
                        'Windows Desktop Version\nSetup your school information',
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
                              : const Text('Setup Windows Version'),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Info Text
                      const Text(
                        'This will create a default administrator account for the Windows desktop version. '
                        'Some cloud features are not available in this version.',
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
    _schoolNameController.dispose();
    _adminNameController.dispose();
    super.dispose();
  }
}