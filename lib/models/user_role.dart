import 'package:hive/hive.dart';

part 'user_role.g.dart';

/// User roles in the school management system
enum UserRole {
  admin,      // Full system access
  principal,  // School-wide management
  teacher,    // Class and student management
  staff,      // Limited administrative access
  parent,     // Read-only access to child's data
  student,    // Personal data access only
}

/// Permission types for different operations
enum Permission {
  // User Management
  createUsers,
  editUsers,
  deleteUsers,
  viewAllUsers,

  // Student Management
  createStudents,
  editStudents,
  deleteStudents,
  viewAllStudents,
  viewOwnClassStudents,

  // Teacher Management
  createTeachers,
  editTeachers,
  deleteTeachers,
  viewAllTeachers,

  // Class Management
  createClasses,
  editClasses,
  deleteClasses,
  viewAllClasses,
  assignStudents,

  // Timetable Management
  createTimetable,
  editTimetable,
  deleteTimetable,
  viewTimetable,

  // Assessment Management
  createAssessments,
  editAssessments,
  deleteAssessments,
  viewAssessments,
  gradeAssessments,

  // Report Generation
  generateReports,
  viewAllReports,
  exportData,

  // System Administration
  systemSettings,
  backupRestore,
  syncManagement,
  viewAnalytics,

  // Communication
  sendNotifications,
  viewMessages,
}

/// User model with role-based access control
@HiveType(typeId: 100)
class User extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String email;

  @HiveField(2)
  final String displayName;

  @HiveField(3)
  final UserRole role;

  @HiveField(4)
  final List<Permission> permissions;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime? lastLoginAt;

  @HiveField(7)
  final bool isActive;

  @HiveField(8)
  final String? profileImageUrl;

  @HiveField(9)
  final Map<String, dynamic> metadata;

  @HiveField(10)
  final String? adminTitle;

  User({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.permissions,
    DateTime? createdAt,
    this.lastLoginAt,
    this.isActive = true,
    this.profileImageUrl,
    Map<String, dynamic>? metadata,
    this.adminTitle,
  }) :
    createdAt = createdAt ?? DateTime.now(),
    metadata = metadata ?? {};

  /// Check if user has a specific permission
  bool hasPermission(Permission permission) {
    return permissions.contains(permission);
  }

  /// Check if user has any of the specified permissions
  bool hasAnyPermission(List<Permission> permissions) {
    return permissions.any((permission) => this.permissions.contains(permission));
  }

  /// Check if user has all of the specified permissions
  bool hasAllPermissions(List<Permission> permissions) {
    return permissions.every((permission) => this.permissions.contains(permission));
  }

  /// Get default permissions for a role
  static List<Permission> getDefaultPermissions(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return Permission.values; // All permissions

      case UserRole.principal:
        return [
          // User Management
          Permission.viewAllUsers,
          Permission.editUsers,

          // Student Management
          Permission.viewAllStudents,
          Permission.editStudents,

          // Teacher Management
          Permission.viewAllTeachers,
          Permission.editTeachers,

          // Class Management
          Permission.viewAllClasses,
          Permission.editClasses,
          Permission.assignStudents,

          // Timetable Management
          Permission.viewTimetable,
          Permission.editTimetable,

          // Assessment Management
          Permission.viewAssessments,
          Permission.editAssessments,
          Permission.gradeAssessments,

          // Report Generation
          Permission.generateReports,
          Permission.viewAllReports,
          Permission.exportData,

          // System Administration
          Permission.systemSettings,
          Permission.backupRestore,
          Permission.syncManagement,
          Permission.viewAnalytics,

          // Communication
          Permission.sendNotifications,
          Permission.viewMessages,
        ];

      case UserRole.teacher:
        return [
          // Student Management
          Permission.viewOwnClassStudents,
          Permission.editStudents,

          // Class Management
          Permission.viewAllClasses,
          Permission.assignStudents,

          // Timetable Management
          Permission.viewTimetable,
          Permission.editTimetable,

          // Assessment Management
          Permission.createAssessments,
          Permission.editAssessments,
          Permission.gradeAssessments,
          Permission.viewAssessments,

          // Report Generation
          Permission.generateReports,
          Permission.viewAllReports,

          // Communication
          Permission.sendNotifications,
          Permission.viewMessages,
        ];

      case UserRole.staff:
        return [
          // Student Management
          Permission.viewAllStudents,
          Permission.editStudents,

          // Class Management
          Permission.viewAllClasses,
          Permission.editClasses,

          // Assessment Management
          Permission.viewAssessments,

          // Report Generation
          Permission.generateReports,
          Permission.viewAllReports,

          // Communication
          Permission.viewMessages,
        ];

      case UserRole.parent:
        return [
          // Student Management (limited to own children)
          Permission.viewOwnClassStudents,

          // Assessment Management (view only)
          Permission.viewAssessments,

          // Communication
          Permission.viewMessages,
        ];

      case UserRole.student:
        return [
          // Personal data access
          Permission.viewAssessments,
          Permission.viewMessages,
        ];
    }
  }

  /// Get role display name
  static String getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.principal:
        return 'Principal';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.staff:
        return 'Staff';
      case UserRole.parent:
        return 'Parent';
      case UserRole.student:
        return 'Student';
    }
  }

  /// Get role description
  static String getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Full system access with all permissions';
      case UserRole.principal:
        return 'School-wide management and oversight';
      case UserRole.teacher:
        return 'Classroom management and student assessment';
      case UserRole.staff:
        return 'Administrative support and data management';
      case UserRole.parent:
        return 'Access to child\'s academic information';
      case UserRole.student:
        return 'Access to personal academic records';
    }
  }

  /// Create a copy with updated fields
  User copyWith({
    String? id,
    String? email,
    String? displayName,
    UserRole? role,
    List<Permission>? permissions,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    String? profileImageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, displayName: $displayName, role: $role)';
  }
}

/// Access Control Manager
class AccessControlManager {
  static User? _currentUser;

  /// Set the current user
  static void setCurrentUser(User? user) {
    _currentUser = user;
  }

  /// Get the current user
  static User? getCurrentUser() {
    return _currentUser;
  }

  /// Check if current user has a specific permission
  static bool hasPermission(Permission permission) {
    return _currentUser?.hasPermission(permission) ?? false;
  }

  /// Check if current user has any of the specified permissions
  static bool hasAnyPermission(List<Permission> permissions) {
    return _currentUser?.hasAnyPermission(permissions) ?? false;
  }

  /// Check if current user has all of the specified permissions
  static bool hasAllPermissions(List<Permission> permissions) {
    return _currentUser?.hasAllPermissions(permissions) ?? false;
  }

  /// Check if current user has a specific role
  static bool hasRole(UserRole role) {
    return _currentUser?.role == role;
  }

  /// Check if current user has any of the specified roles
  static bool hasAnyRole(List<UserRole> roles) {
    return _currentUser != null && roles.contains(_currentUser!.role);
  }

  /// Check if current user is admin
  static bool isAdmin() {
    return hasRole(UserRole.admin);
  }

  /// Check if current user is principal or admin
  static bool isPrincipalOrAdmin() {
    return hasAnyRole([UserRole.admin, UserRole.principal]);
  }

  /// Check if current user is teacher or higher
  static bool isTeacherOrHigher() {
    return hasAnyRole([UserRole.admin, UserRole.principal, UserRole.teacher]);
  }

  /// Check if current user can access student data
  static bool canAccessStudentData(String? studentId) {
    if (_currentUser == null) return false;

    // Admin and principal can access all student data
    if (isPrincipalOrAdmin()) return true;

    // Teachers can access their class students
    if (hasRole(UserRole.teacher)) {
      // TODO: Implement class-based access control
      return true; // For now, allow all teachers
    }

    // Parents can only access their children's data
    if (hasRole(UserRole.parent)) {
      // TODO: Implement parent-child relationship check
      return studentId == _currentUser!.metadata['childId'];
    }

    // Students can only access their own data
    if (hasRole(UserRole.student)) {
      return studentId == _currentUser!.id;
    }

    return false;
  }

  /// Check if current user can modify data
  static bool canModifyData() {
    return hasAnyRole([UserRole.admin, UserRole.principal, UserRole.teacher, UserRole.staff]);
  }

  /// Check if current user can delete data
  static bool canDeleteData() {
    return hasAnyRole([UserRole.admin, UserRole.principal]);
  }

  /// Check if current user can manage users
  static bool canManageUsers() {
    return hasAnyRole([UserRole.admin, UserRole.principal]);
  }

  /// Check if current user can view system settings
  static bool canViewSystemSettings() {
    return hasAnyRole([UserRole.admin, UserRole.principal]);
  }

  /// Check if current user can manage system settings
  static bool canManageSystemSettings() {
    return hasRole(UserRole.admin);
  }

  /// Check if current user can view analytics
  static bool canViewAnalytics() {
    return hasPermission(Permission.viewAnalytics);
  }
}