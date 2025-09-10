import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models.dart';
import '../services/firebase_service.dart';
import '../services/user_sync_service.dart';

/// User Profile Header Widget
/// Displays the logged-in user's name and profile information prominently
class UserProfileHeader extends StatefulWidget {
  final bool showAvatar;
  final bool showRole;
  final bool showSyncStatus;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSyncTap;

  const UserProfileHeader({
    super.key,
    this.showAvatar = true,
    this.showRole = true,
    this.showSyncStatus = false,
    this.onProfileTap,
    this.onSyncTap,
  });

  @override
  State<UserProfileHeader> createState() => _UserProfileHeaderState();
}

class _UserProfileHeaderState extends State<UserProfileHeader> {
  late Stream<dynamic> _syncEventStream;
  Map<String, dynamic>? _syncStatus;

  @override
  void initState() {
    super.initState();
    _syncEventStream = UserSyncService.syncEventStream;
    _loadSyncStatus();
  }

  Future<void> _loadSyncStatus() async {
    final currentUser = FirebaseService.currentUser;
    if (currentUser != null) {
      final status = await UserSyncService.getSyncStatus(currentUser.uid);
      if (mounted) {
        setState(() {
          _syncStatus = status;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<dynamic>(
      stream: _syncEventStream,
      builder: (context, snapshot) {
        // Refresh sync status when sync events occur
        if (snapshot.hasData) {
          _loadSyncStatus();
        }

        return ValueListenableBuilder<Box<User>>(
          valueListenable: Hive.box<User>('users').listenable(),
          builder: (context, usersBox, child) {
            final currentUser = FirebaseService.currentUser;
            User? userData;

            if (currentUser != null) {
              userData = usersBox.get(currentUser.uid);
            }

            if (userData == null && currentUser == null) {
              return _buildGuestHeader();
            }

            return _buildUserHeader(context, userData, currentUser);
          },
        );
      },
    );
  }

  Widget _buildUserHeader(BuildContext context, User? userData, dynamic currentUser) {
    final displayName = userData?.displayName ??
                      currentUser?.displayName ??
                      userData?.email.split('@')[0] ??
                      'User';

    final email = userData?.email ?? currentUser?.email ?? '';
    final photoUrl = userData?.photoUrl ?? currentUser?.photoURL;
    final role = userData?.role ?? 'student';

    return GestureDetector(
      onTap: widget.onProfileTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Avatar
            if (widget.showAvatar) ...[
              CircleAvatar(
                radius: 24,
                backgroundColor: Theme.of(context).primaryColor,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
            ],

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Display Name
                  Text(
                    displayName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Email
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  // Role
                  if (widget.showRole) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getRoleColor(role).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getRoleColor(role).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getRoleDisplayName(role),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: _getRoleColor(role),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Sync Status
            if (widget.showSyncStatus) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onSyncTap,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getSyncStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getSyncStatusIcon(),
                    size: 16,
                    color: _getSyncStatusColor(),
                  ),
                ),
              ),
            ],

            // Menu Icon
            if (widget.onProfileTap != null) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuestHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[400],
            child: const Icon(
              Icons.person,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Guest User',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Sign in to access all features',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
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
      default:
        return Colors.teal;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
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
      default:
        return 'Student';
    }
  }

  Color _getSyncStatusColor() {
    if (_syncStatus == null) return Colors.grey;

    final isOnline = _syncStatus!['isOnline'] as bool? ?? false;
    final pendingChanges = _syncStatus!['pendingChangesCount'] as int? ?? 0;
    final error = _syncStatus!['error'] as String?;

    if (error != null) return Colors.red;
    if (!isOnline) return Colors.orange;
    if (pendingChanges > 0) return Colors.blue;

    return Colors.green;
  }

  IconData _getSyncStatusIcon() {
    if (_syncStatus == null) return Icons.sync;

    final isOnline = _syncStatus!['isOnline'] as bool? ?? false;
    final pendingChanges = _syncStatus!['pendingChangesCount'] as int? ?? 0;
    final error = _syncStatus!['error'] as String?;

    if (error != null) return Icons.sync_problem;
    if (!isOnline) return Icons.sync_disabled;
    if (pendingChanges > 0) return Icons.sync;

    return Icons.check_circle;
  }
}

/// Compact User Profile Widget for App Bar
class CompactUserProfile extends StatelessWidget {
  final VoidCallback? onTap;

  const CompactUserProfile({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<User>>(
      valueListenable: Hive.box<User>('users').listenable(),
      builder: (context, usersBox, child) {
        final currentUser = FirebaseService.currentUser;
        User? userData;

        if (currentUser != null) {
          userData = usersBox.get(currentUser.uid);
        }

        final displayName = userData?.displayName ??
                          currentUser?.displayName ??
                          userData?.email.split('@')[0] ??
                          'User';

        final photoUrl = userData?.photoUrl ?? currentUser?.photoURL;

        return GestureDetector(
          onTap: onTap,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).primaryColor,
                backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                child: photoUrl == null
                    ? Text(
                        displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 8),

              // Name
              Text(
                displayName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).primaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(width: 4),

              // Dropdown Icon
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: Theme.of(context).primaryColor,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// User Profile Card for Profile Screen
class UserProfileCard extends StatelessWidget {
  final VoidCallback? onEditProfile;
  final VoidCallback? onSignOut;

  const UserProfileCard({
    super.key,
    this.onEditProfile,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Box<User>>(
      valueListenable: Hive.box<User>('users').listenable(),
      builder: (context, usersBox, child) {
        final currentUser = FirebaseService.currentUser;
        User? userData;

        if (currentUser != null) {
          userData = usersBox.get(currentUser.uid);
        }

        final displayName = userData?.displayName ??
                          currentUser?.displayName ??
                          'User';

        final email = userData?.email ?? currentUser?.email ?? '';
        final photoUrl = userData?.photoUrl ?? currentUser?.photoURL;
        final role = userData?.role ?? 'student';
        final schoolName = userData?.schoolName ?? '';

        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Theme.of(context).primaryColor,
                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? Text(
                          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        )
                      : null,
                ),

                const SizedBox(height: 16),

                // Name
                Text(
                  displayName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 4),

                // Email
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getRoleColor(role).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getRoleDisplayName(role),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getRoleColor(role),
                    ),
                  ),
                ),

                // School Name
                if (schoolName.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    schoolName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    if (onEditProfile != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEditProfile,
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Profile'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),

                    if (onEditProfile != null && onSignOut != null)
                      const SizedBox(width: 12),

                    if (onSignOut != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onSignOut,
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign Out'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
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
      default:
        return Colors.teal;
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role.toLowerCase()) {
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
      default:
        return 'Student';
    }
  }
}