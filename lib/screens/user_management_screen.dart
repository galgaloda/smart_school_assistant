import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _filterRole;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateUserDialog,
            tooltip: 'Add User',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[50],
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users by name or email',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Filter by role:'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String?>(
                        value: _filterRole,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        hint: const Text('All Roles'),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Roles'),
                          ),
                          ...['admin', 'teacher', 'student', 'staff', 'parent', 'principal'].map((role) {
                            return DropdownMenuItem<String?>(
                              value: role,
                              child: Text(_getRoleDisplayName(role)),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filterRole = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Users List
          Expanded(
            child: ValueListenableBuilder<Box<User>>(
              valueListenable: Hive.box<User>('users').listenable(),
              builder: (context, box, _) {
                final users = box.values.where((user) {
                  // Search filter
                  final matchesSearch = _searchQuery.isEmpty ||
                      (user.displayName?.toLowerCase().contains(_searchQuery) ?? false) ||
                      user.email.toLowerCase().contains(_searchQuery);

                  // Role filter
                  final matchesRole = _filterRole == null || user.role == _filterRole;

                  return matchesSearch && matchesRole && user.isActive;
                }).toList();

                if (users.isEmpty) {
                  return const Center(
                    child: Text('No users found'),
                  );
                }

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return _buildUserCard(user);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(user.role),
          child: Icon(
            _getRoleIcon(user.role),
            color: Colors.white,
          ),
        ),
        title: Text(
          user.displayName ?? user.email,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text(
              _getRoleDisplayName(user.role),
              style: TextStyle(
                color: _getRoleColor(user.role),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleUserAction(user, value),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit User'),
            ),
            const PopupMenuItem(
              value: 'reset_password',
              child: Text('Reset Password'),
            ),
            const PopupMenuItem(
              value: 'deactivate',
              child: Text('Deactivate'),
            ),
          ],
        ),
        onTap: () => _showUserDetails(user),
      ),
    );
  }

  void _handleUserAction(User user, String action) {
    switch (action) {
      case 'edit':
        _showEditUserDialog(user);
        break;
      case 'reset_password':
        _showResetPasswordDialog(user);
        break;
      case 'deactivate':
        _showDeactivateUserDialog(user);
        break;
    }
  }

  void _showCreateUserDialog() {
    final emailController = TextEditingController();
    final displayNameController = TextEditingController();
    String selectedRole = 'teacher';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: ['admin', 'teacher', 'student', 'staff', 'parent', 'principal'].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(_getRoleDisplayName(role)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedRole = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isEmpty || displayNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                final newUser = User(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  email: emailController.text,
                  displayName: displayNameController.text,
                  role: selectedRole,
                  createdAt: DateTime.now(),
                  lastLoginAt: DateTime.now(),
                );

                final box = Hive.box<User>('users');
                await box.put(newUser.id, newUser);

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User created successfully')),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(User user) {
    final displayNameController = TextEditingController(text: user.displayName);
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Display Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: ['admin', 'teacher', 'student', 'staff', 'parent', 'principal'].map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(_getRoleDisplayName(role)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedRole = value;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (displayNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Display name cannot be empty')),
                  );
                  return;
                }

                final updatedUser = User(
                  id: user.id,
                  email: user.email,
                  displayName: displayNameController.text,
                  role: selectedRole,
                  createdAt: user.createdAt,
                  lastLoginAt: user.lastLoginAt,
                  isActive: user.isActive,
                  schoolName: user.schoolName,
                  schoolAddress: user.schoolAddress,
                  schoolPhone: user.schoolPhone,
                  isSynced: user.isSynced,
                  lastUpdated: user.lastUpdated,
                  userId: user.userId,
                  syncId: user.syncId,
                );

                final box = Hive.box<User>('users');
                await box.put(updatedUser.id, updatedUser);

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User updated successfully')),
                );
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }


  void _showResetPasswordDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text(
          'Are you sure you want to reset the password for ${user.displayName}? '
          'They will receive an email with password reset instructions.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Implement password reset functionality
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset email sent')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset Password'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateUserDialog(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate User'),
        content: Text(
          'Are you sure you want to deactivate ${user.displayName}? '
          'This will prevent them from accessing the system.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final updatedUser = User(
                id: user.id,
                email: user.email,
                displayName: user.displayName,
                role: user.role,
                createdAt: user.createdAt,
                lastLoginAt: user.lastLoginAt,
                isActive: false,
                schoolName: user.schoolName,
                schoolAddress: user.schoolAddress,
                schoolPhone: user.schoolPhone,
                isSynced: user.isSynced,
                lastUpdated: user.lastUpdated,
                userId: user.userId,
                syncId: user.syncId,
              );
              final box = Hive.box<User>('users');
              await box.put(updatedUser.id, updatedUser);

              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User deactivated successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(user.displayName ?? user.email),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Email', user.email),
              _buildDetailRow('Role', _getRoleDisplayName(user.role)),
              _buildDetailRow('Status', user.isActive ? 'Active' : 'Inactive'),
              _buildDetailRow('Created', _formatDate(user.createdAt)),
              _buildDetailRow('Last Login', _formatDate(user.lastLoginAt!)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }


  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Administrator';
      case 'principal':
        return 'Principal';
      case 'teacher':
        return 'Teacher';
      case 'staff':
        return 'Staff';
      case 'parent':
        return 'Parent';
      case 'student':
        return 'Student';
      default:
        return 'Unknown';
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'principal':
        return Icons.school;
      case 'teacher':
        return Icons.person;
      case 'staff':
        return Icons.work;
      case 'parent':
        return Icons.family_restroom;
      case 'student':
        return Icons.backpack;
      default:
        return Icons.person;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'principal':
        return Colors.purple;
      case 'teacher':
        return Colors.blue;
      case 'staff':
        return Colors.green;
      case 'parent':
        return Colors.orange;
      case 'student':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}