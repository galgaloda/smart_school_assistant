import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_role.dart' as user_role;
import 'firebase_service.dart';

/// Authentication middleware for route protection and session management
class AuthMiddleware {
  static const String _authStateBoxName = 'auth_state';
  static const String _lastRouteKey = 'last_route';
  static const String _authTimestampKey = 'auth_timestamp';

  /// Check if user is authenticated and session is valid
  static Future<bool> isAuthenticated() async {
    try {
      // Check Firebase authentication
      if (!FirebaseService.isAuthenticated) {
        print('[AUTH_MIDDLEWARE] Firebase authentication failed');
        return false;
      }

      // Check session validity
      if (!FirebaseService.isSessionValid()) {
        print('[AUTH_MIDDLEWARE] Session expired');
        return false;
      }

      // Check if user has valid role in AccessControlManager
      final currentUser = user_role.AccessControlManager.getCurrentUser();
      if (currentUser == null) {
        print('[AUTH_MIDDLEWARE] No user in AccessControlManager');
        return false;
      }

      print('[AUTH_MIDDLEWARE] Authentication check passed');
      return true;
    } catch (e) {
      print('[AUTH_MIDDLEWARE] Authentication check failed: $e');
      return false;
    }
  }

  /// Check if user has required permission for a route
  static bool hasPermission(user_role.Permission permission) {
    return user_role.AccessControlManager.hasPermission(permission);
  }

  /// Check if user has required role
  static bool hasRole(user_role.UserRole role) {
    return user_role.AccessControlManager.hasRole(role);
  }

  /// Check if user has any of the required permissions
  static bool hasAnyPermission(List<user_role.Permission> permissions) {
    return user_role.AccessControlManager.hasAnyPermission(permissions);
  }

  /// Check if user has any of the required roles
  static bool hasAnyRole(List<user_role.UserRole> roles) {
    return user_role.AccessControlManager.hasAnyRole(roles);
  }

  /// Guard for admin-only routes
  static bool isAdmin() {
    return user_role.AccessControlManager.isAdmin();
  }

  /// Guard for principal or admin routes
  static bool isPrincipalOrAdmin() {
    return user_role.AccessControlManager.isPrincipalOrAdmin();
  }

  /// Guard for teacher or higher privilege routes
  static bool isTeacherOrHigher() {
    return user_role.AccessControlManager.isTeacherOrHigher();
  }

  /// Get current user information
  static user_role.User? getCurrentUser() {
    return user_role.AccessControlManager.getCurrentUser();
  }

  /// Get current user role
  static user_role.UserRole? getCurrentUserRole() {
    final user = getCurrentUser();
    return user?.role;
  }

  /// Get current user permissions
  static List<user_role.Permission> getCurrentUserPermissions() {
    final user = getCurrentUser();
    return user?.permissions ?? [];
  }

  /// Save current route for session restoration
  static Future<void> saveCurrentRoute(String routeName) async {
    try {
      final authStateBox = await Hive.openBox(_authStateBoxName);
      await authStateBox.put(_lastRouteKey, routeName);
      await authStateBox.put(_authTimestampKey, DateTime.now().toIso8601String());
      print('[AUTH_MIDDLEWARE] Route saved: $routeName');
    } catch (e) {
      print('[AUTH_MIDDLEWARE] Failed to save route: $e');
    }
  }

  /// Get last saved route
  static Future<String?> getLastRoute() async {
    try {
      final authStateBox = await Hive.openBox(_authStateBoxName);
      return authStateBox.get(_lastRouteKey) as String?;
    } catch (e) {
      print('[AUTH_MIDDLEWARE] Failed to get last route: $e');
      return null;
    }
  }

  /// Clear saved route
  static Future<void> clearLastRoute() async {
    try {
      final authStateBox = await Hive.openBox(_authStateBoxName);
      await authStateBox.delete(_lastRouteKey);
      print('[AUTH_MIDDLEWARE] Last route cleared');
    } catch (e) {
      print('[AUTH_MIDDLEWARE] Failed to clear last route: $e');
    }
  }

  /// Check if user can access a specific route
  static Future<RouteAccessResult> canAccessRoute(String routeName) async {
    // First check if user is authenticated
    if (!await isAuthenticated()) {
      return RouteAccessResult(
        canAccess: false,
        reason: 'User not authenticated',
        redirectTo: '/login',
      );
    }

    // Route-specific permission checks
    switch (routeName) {
      case '/admin':
      case '/management':
        if (!isAdmin()) {
          return RouteAccessResult(
            canAccess: false,
            reason: 'Admin access required',
            redirectTo: '/home',
          );
        }
        break;

      case '/teacher':
        if (!isTeacherOrHigher()) {
          return RouteAccessResult(
            canAccess: false,
            reason: 'Teacher or higher privileges required',
            redirectTo: '/home',
          );
        }
        break;

      case '/analytics':
        if (!hasPermission(user_role.Permission.viewAnalytics)) {
          return RouteAccessResult(
            canAccess: false,
            reason: 'Analytics permission required',
            redirectTo: '/home',
          );
        }
        break;

      case '/settings':
        if (!hasPermission(user_role.Permission.systemSettings)) {
          return RouteAccessResult(
            canAccess: false,
            reason: 'System settings permission required',
            redirectTo: '/home',
          );
        }
        break;

      default:
        // Default routes that require basic authentication
        break;
    }

    return RouteAccessResult(canAccess: true);
  }

  /// Handle route navigation with authentication checks
  static Future<String?> handleRouteNavigation(String routeName) async {
    final accessResult = await canAccessRoute(routeName);

    if (!accessResult.canAccess) {
      print('[AUTH_MIDDLEWARE] Access denied to $routeName: ${accessResult.reason}');
      return accessResult.redirectTo;
    }

    // Save current route for session restoration
    await saveCurrentRoute(routeName);
    return null; // No redirect needed
  }

  /// Get authentication status information
  static Future<Map<String, dynamic>> getAuthStatus() async {
    final currentUser = getCurrentUser();

    return {
      'isAuthenticated': await isAuthenticated(),
      'currentUser': currentUser?.toString(),
      'userRole': currentUser?.role.toString(),
      'userPermissions': currentUser?.permissions.map((p) => p.toString()).toList() ?? [],
      'sessionValid': FirebaseService.isSessionValid(),
      'firebaseAuthenticated': FirebaseService.isAuthenticated,
      'lastRoute': await getLastRoute(),
      'emailVerified': FirebaseService.isEmailVerified,
    };
  }

  /// Force refresh authentication state
  static Future<void> refreshAuthState() async {
    try {
      // Update user activity
      await FirebaseService.updateUserActivity();

      // Re-validate session
      if (!FirebaseService.isSessionValid()) {
        print('[AUTH_MIDDLEWARE] Session invalid during refresh');
        return;
      }

      print('[AUTH_MIDDLEWARE] Authentication state refreshed');
    } catch (e) {
      print('[AUTH_MIDDLEWARE] Failed to refresh auth state: $e');
    }
  }

  /// Clean up authentication state
  static Future<void> cleanup() async {
    try {
      await clearLastRoute();
      print('[AUTH_MIDDLEWARE] Authentication state cleaned up');
    } catch (e) {
      print('[AUTH_MIDDLEWARE] Failed to cleanup auth state: $e');
    }
  }

  /// Handle logout process
  static Future<void> handleLogout() async {
    try {
      // Clear local authentication state
      user_role.AccessControlManager.setCurrentUser(null);

      // Sign out from Firebase
      await FirebaseService.signOut();

      // Clear saved route
      await clearLastRoute();

      print('[AUTH_MIDDLEWARE] Logout completed successfully');
    } catch (e) {
      print('[AUTH_MIDDLEWARE] Logout failed: $e');
      rethrow;
    }
  }

  /// Check if user needs to verify email
  static bool needsEmailVerification() {
    return FirebaseService.isAuthenticated && !FirebaseService.isEmailVerified;
  }

  /// Send email verification
  static Future<void> sendEmailVerification() async {
    await FirebaseService.sendEmailVerification();
  }

  /// Get user display information
  static Map<String, String?> getUserDisplayInfo() {
    final user = getCurrentUser();
    final firebaseUser = FirebaseService.currentUser;

    return {
      'displayName': user?.displayName ?? firebaseUser?.displayName ?? 'Unknown User',
      'email': user?.email ?? firebaseUser?.email ?? '',
      'role': user?.role.toString() ?? 'Unknown',
      'userId': user?.id ?? firebaseUser?.uid ?? '',
    };
  }
}

/// Result of route access check
class RouteAccessResult {
  final bool canAccess;
  final String? reason;
  final String? redirectTo;

  RouteAccessResult({
    required this.canAccess,
    this.reason,
    this.redirectTo,
  });

  @override
  String toString() {
    return 'RouteAccessResult(canAccess: $canAccess, reason: $reason, redirectTo: $redirectTo)';
  }
}

/// Authentication guard widget for protecting routes
class AuthGuard extends StatelessWidget {
  final Widget child;
  final List<user_role.Permission>? requiredPermissions;
  final List<user_role.UserRole>? requiredRoles;
  final Widget? fallbackWidget;
  final String? fallbackRoute;

  const AuthGuard({
    super.key,
    required this.child,
    this.requiredPermissions,
    this.requiredRoles,
    this.fallbackWidget,
    this.fallbackRoute,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _checkAccess(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data == true) {
          return child;
        }

        // Access denied
        if (fallbackWidget != null) {
          return fallbackWidget!;
        }

        if (fallbackRoute != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(fallbackRoute!);
          });
        }

        // Default fallback - redirect to login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/login');
        });

        return const Scaffold(
          body: Center(
            child: Text('Access Denied'),
          ),
        );
      },
    );
  }

  Future<bool> _checkAccess() async {
    // Check authentication
    if (!await AuthMiddleware.isAuthenticated()) {
      return false;
    }

    // Check required permissions
    if (requiredPermissions != null && requiredPermissions!.isNotEmpty) {
      if (!AuthMiddleware.hasAnyPermission(requiredPermissions!)) {
        return false;
      }
    }

    // Check required roles
    if (requiredRoles != null && requiredRoles!.isNotEmpty) {
      if (!AuthMiddleware.hasAnyRole(requiredRoles!)) {
        return false;
      }
    }

    return true;
  }
}