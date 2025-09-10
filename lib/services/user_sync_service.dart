import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models.dart';
import 'firebase_service.dart';
import 'comprehensive_auth_service.dart';

/// User Synchronization Service
/// Handles robust cross-device synchronization of user credentials
/// with conflict resolution and offline support
class UserSyncService {
  static const String _syncBoxName = 'user_sync_data';
  static const String _syncMetadataKey = 'sync_metadata';
  static const String _pendingChangesKey = 'pending_changes';
  static const Duration _syncInterval = Duration(minutes: 5);

  static bool _isInitialized = false;
  static Timer? _syncTimer;
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static final StreamController<SyncEvent> _syncEventController = StreamController<SyncEvent>.broadcast();

  /// Initialize the user sync service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.openBox(_syncBoxName);
      await _setupConnectivityMonitoring();
      await _startPeriodicSync();

      // Listen for authentication changes
      FirebaseService.auth.authStateChanges().listen((user) {
        if (user != null) {
          _handleUserAuthenticated(user);
        } else {
          _handleUserSignedOut();
        }
      });

      _isInitialized = true;
      print('[USER_SYNC] User synchronization service initialized');

    } catch (e) {
      print('[USER_SYNC] Failed to initialize user sync service: $e');
      rethrow;
    }
  }

  /// Setup connectivity monitoring
  static Future<void> _setupConnectivityMonitoring() async {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((result) => result != ConnectivityResult.none);

      if (isOnline) {
        // Trigger sync when coming back online
        _performFullSync();
      }
    });
  }

  /// Start periodic sync
  static Future<void> _startPeriodicSync() async {
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      _performIncrementalSync();
    });
  }

  /// Handle user authentication
  static Future<void> _handleUserAuthenticated(firebase_auth.User firebaseUser) async {
    try {
      // Load user's sync metadata
      await _loadUserSyncMetadata(firebaseUser.uid);

      // Perform initial sync
      await _performFullSync();

      // Start listening for remote changes
      _startRemoteChangeListener(firebaseUser.uid);

      _emitSyncEvent(SyncEventType.userAuthenticated, 'User authenticated and sync initialized');

    } catch (e) {
      print('[USER_SYNC] Failed to handle user authentication: $e');
    }
  }

  /// Handle user sign out
  static Future<void> _handleUserSignedOut() async {
    try {
      // Stop listening for remote changes
      await _stopRemoteChangeListener();

      // Clear local sync data
      await _clearLocalSyncData();

      _emitSyncEvent(SyncEventType.userSignedOut, 'User signed out and sync stopped');

    } catch (e) {
      print('[USER_SYNC] Failed to handle user sign out: $e');
    }
  }

  /// Perform full synchronization
  static Future<SyncResult> _performFullSync() async {
    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) {
        return SyncResult(success: false, error: 'No authenticated user');
      }

      _emitSyncEvent(SyncEventType.syncStarted, 'Full synchronization started');

      // Sync user profile
      await _syncUserProfile(currentUser.uid);

      // Sync user preferences
      await _syncUserPreferences(currentUser.uid);

      // Sync user data
      await _syncUserData(currentUser.uid);

      // Process pending changes
      await _processPendingChanges(currentUser.uid);

      // Update sync metadata
      await _updateSyncMetadata(currentUser.uid);

      _emitSyncEvent(SyncEventType.syncCompleted, 'Full synchronization completed');
      return SyncResult(success: true);

    } catch (e) {
      _emitSyncEvent(SyncEventType.syncFailed, 'Full synchronization failed: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// Perform incremental synchronization
  static Future<SyncResult> _performIncrementalSync() async {
    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) return SyncResult(success: true); // No-op if not authenticated

      // Check for remote changes
      final hasRemoteChanges = await _checkForRemoteChanges(currentUser.uid);
      final hasLocalChanges = await _checkForLocalChanges(currentUser.uid);

      if (!hasRemoteChanges && !hasLocalChanges) {
        return SyncResult(success: true); // No changes to sync
      }

      _emitSyncEvent(SyncEventType.syncStarted, 'Incremental synchronization started');

      // Sync changes
      if (hasRemoteChanges) {
        await _syncRemoteChanges(currentUser.uid);
      }

      if (hasLocalChanges) {
        await _syncLocalChanges(currentUser.uid);
      }

      // Update sync metadata
      await _updateSyncMetadata(currentUser.uid);

      _emitSyncEvent(SyncEventType.syncCompleted, 'Incremental synchronization completed');
      return SyncResult(success: true);

    } catch (e) {
      _emitSyncEvent(SyncEventType.syncFailed, 'Incremental synchronization failed: $e');
      return SyncResult(success: false, error: e.toString());
    }
  }

  /// Sync user profile
  static Future<void> _syncUserProfile(String userId) async {
    try {
      // Get remote user profile
      final remoteProfile = await FirebaseService.firestore
          .collection('users')
          .doc(userId)
          .get();

      if (remoteProfile.exists) {
        final remoteData = remoteProfile.data()!;
        final usersBox = Hive.box<User>('users');

        // Get local user
        User? localUser = usersBox.get(userId);

        if (localUser == null) {
          // Create local user from remote data
          localUser = User(
            id: userId,
            email: remoteData['email'] ?? '',
            displayName: remoteData['displayName'],
            photoUrl: remoteData['photoUrl'],
            role: remoteData['role'] ?? 'student',
            createdAt: (remoteData['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            lastLoginAt: (remoteData['lastLoginAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            isActive: remoteData['isActive'] ?? true,
            schoolName: remoteData['schoolName'],
          );
          await usersBox.put(userId, localUser);
        } else {
          // Update local user with remote data (resolve conflicts)
          localUser = await _resolveUserProfileConflict(localUser, remoteData);
          await usersBox.put(userId, localUser);
        }
      }

    } catch (e) {
      print('[USER_SYNC] Failed to sync user profile: $e');
    }
  }

  /// Sync user preferences
  static Future<void> _syncUserPreferences(String userId) async {
    try {
      final remotePrefs = await FirebaseService.firestore
          .collection('user_preferences')
          .doc(userId)
          .get();

      if (remotePrefs.exists) {
        final remoteData = remotePrefs.data()!;
        final prefsBox = Hive.box('user_preferences_$userId');

        // Merge remote preferences with local ones
        final localPrefs = Map<String, dynamic>.from(prefsBox.toMap());
        final mergedPrefs = _mergePreferences(localPrefs, remoteData);

        // Save merged preferences
        await prefsBox.clear();
        for (final entry in mergedPrefs.entries) {
          await prefsBox.put(entry.key, entry.value);
        }
      }

    } catch (e) {
      print('[USER_SYNC] Failed to sync user preferences: $e');
    }
  }

  /// Sync user data
  static Future<void> _syncUserData(String userId) async {
    try {
      // Sync various user data collections
      await _syncCollection('user_settings', userId);
      await _syncCollection('user_sessions', userId);
      await _syncCollection('user_activity', userId);

    } catch (e) {
      print('[USER_SYNC] Failed to sync user data: $e');
    }
  }

  /// Sync a specific collection
  static Future<void> _syncCollection(String collectionName, String userId) async {
    try {
      final remoteDocs = await FirebaseService.firestore
          .collection(collectionName)
          .where('userId', isEqualTo: userId)
          .get();

      final localBox = Hive.box('${collectionName}_$userId');

      for (final doc in remoteDocs.docs) {
        final data = doc.data();
        data['lastSynced'] = DateTime.now().toIso8601String();

        // Check for conflicts
        final localData = localBox.get(doc.id);
        if (localData != null) {
          final mergedData = await _resolveDataConflict(doc.id, localData, data, collectionName);
          await localBox.put(doc.id, mergedData);
        } else {
          await localBox.put(doc.id, data);
        }
      }

    } catch (e) {
      print('[USER_SYNC] Failed to sync collection $collectionName: $e');
    }
  }

  /// Process pending changes
  static Future<void> _processPendingChanges(String userId) async {
    try {
      final syncBox = await Hive.openBox(_syncBoxName);
      final pendingChanges = syncBox.get(_pendingChangesKey) as Map<String, dynamic>? ?? {};

      final userChanges = pendingChanges[userId] as List<dynamic>? ?? [];

      for (final change in userChanges) {
        await _applyPendingChange(change, userId);
      }

      // Clear processed changes
      pendingChanges.remove(userId);
      await syncBox.put(_pendingChangesKey, pendingChanges);

    } catch (e) {
      print('[USER_SYNC] Failed to process pending changes: $e');
    }
  }

  /// Apply a pending change
  static Future<void> _applyPendingChange(Map<String, dynamic> change, String userId) async {
    try {
      final collection = change['collection'] as String;
      final docId = change['docId'] as String;
      final data = change['data'] as Map<String, dynamic>;
      final operation = change['operation'] as String;

      switch (operation) {
        case 'create':
        case 'update':
          await FirebaseService.firestore
              .collection(collection)
              .doc(docId)
              .set(data, SetOptions(merge: true));
          break;

        case 'delete':
          await FirebaseService.firestore
              .collection(collection)
              .doc(docId)
              .delete();
          break;
      }

    } catch (e) {
      print('[USER_SYNC] Failed to apply pending change: $e');
    }
  }

  /// Queue a change for sync
  static Future<void> queueChangeForSync(
    String collection,
    String docId,
    Map<String, dynamic> data,
    String operation,
  ) async {
    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) return;

      final syncBox = await Hive.openBox(_syncBoxName);
      final pendingChanges = syncBox.get(_pendingChangesKey) as Map<String, dynamic>? ?? {};

      final userChanges = pendingChanges[currentUser.uid] as List<dynamic>? ?? [];

      userChanges.add({
        'collection': collection,
        'docId': docId,
        'data': data,
        'operation': operation,
        'timestamp': DateTime.now().toIso8601String(),
      });

      pendingChanges[currentUser.uid] = userChanges;
      await syncBox.put(_pendingChangesKey, pendingChanges);

      // Try to sync immediately if online
      if (await _isOnline()) {
        await _performIncrementalSync();
      }

    } catch (e) {
      print('[USER_SYNC] Failed to queue change for sync: $e');
    }
  }

  /// Resolve user profile conflict
  static Future<User> _resolveUserProfileConflict(User localUser, Map<String, dynamic> remoteData) async {
    // Simple conflict resolution: prefer newer data
    final remoteLastModified = (remoteData['lastModified'] as Timestamp?)?.toDate();
    final localLastModified = localUser.lastLoginAt;

    if (remoteLastModified != null) {
      if (remoteLastModified.isAfter(localLastModified)) {
        // Use remote data
        return User(
          id: localUser.id,
          email: remoteData['email'] ?? localUser.email,
          displayName: remoteData['displayName'] ?? localUser.displayName,
          photoUrl: remoteData['photoUrl'] ?? localUser.photoUrl,
          role: remoteData['role'] ?? localUser.role,
          createdAt: localUser.createdAt,
          lastLoginAt: remoteLastModified,
          isActive: remoteData['isActive'] ?? localUser.isActive,
          schoolName: remoteData['schoolName'] ?? localUser.schoolName,
        );
      }
    }

    // Keep local data
    return localUser;
  }

  /// Resolve data conflict
  static Future<Map<String, dynamic>> _resolveDataConflict(
    String docId,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
    String collection,
  ) async {
    // Simple conflict resolution: merge data, prefer remote for conflicts
    final merged = Map<String, dynamic>.from(localData);

    for (final entry in remoteData.entries) {
      if (!merged.containsKey(entry.key) || _shouldPreferRemote(entry.key)) {
        merged[entry.key] = entry.value;
      }
    }

    return merged;
  }

  /// Check if should prefer remote data for a field
  static bool _shouldPreferRemote(String field) {
    // Fields that should always prefer remote data
    const remotePreferredFields = [
      'lastLoginAt',
      'lastModified',
      'lastSynced',
      'serverTimestamp',
    ];

    return remotePreferredFields.contains(field);
  }

  /// Merge preferences
  static Map<String, dynamic> _mergePreferences(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) {
    final merged = Map<String, dynamic>.from(local);

    for (final entry in remote.entries) {
      if (!merged.containsKey(entry.key)) {
        merged[entry.key] = entry.value;
      }
      // For existing keys, keep local preferences (user's choice)
    }

    return merged;
  }

  /// Check for remote changes
  static Future<bool> _checkForRemoteChanges(String userId) async {
    try {
      final syncMetadata = await _getSyncMetadata(userId);
      if (syncMetadata == null) return true; // No metadata means we need to sync

      final lastSync = DateTime.parse(syncMetadata['lastSync']);
      final now = DateTime.now();

      // Check if it's been more than the sync interval
      return now.difference(lastSync) > _syncInterval;

    } catch (e) {
      return true; // Assume changes if we can't check
    }
  }

  /// Check for local changes
  static Future<bool> _checkForLocalChanges(String userId) async {
    try {
      final syncBox = await Hive.openBox(_syncBoxName);
      final pendingChanges = syncBox.get(_pendingChangesKey) as Map<String, dynamic>? ?? {};
      final userChanges = pendingChanges[userId] as List<dynamic>? ?? [];

      return userChanges.isNotEmpty;

    } catch (e) {
      return false;
    }
  }

  /// Sync remote changes
  static Future<void> _syncRemoteChanges(String userId) async {
    // Implementation for syncing remote changes
    await _syncUserProfile(userId);
    await _syncUserPreferences(userId);
    await _syncUserData(userId);
  }

  /// Sync local changes
  static Future<void> _syncLocalChanges(String userId) async {
    await _processPendingChanges(userId);
  }

  /// Load user sync metadata
  static Future<void> _loadUserSyncMetadata(String userId) async {
    try {
      final remoteMetadata = await FirebaseService.firestore
          .collection('user_sync_metadata')
          .doc(userId)
          .get();

      if (remoteMetadata.exists) {
        final syncBox = await Hive.openBox(_syncBoxName);
        await syncBox.put(_syncMetadataKey, remoteMetadata.data());
      }

    } catch (e) {
      print('[USER_SYNC] Failed to load user sync metadata: $e');
    }
  }

  /// Update sync metadata
  static Future<void> _updateSyncMetadata(String userId) async {
    try {
      final metadata = {
        'userId': userId,
        'lastSync': DateTime.now().toIso8601String(),
        'deviceId': await _getDeviceId(),
        'syncVersion': '1.0',
      };

      // Save locally
      final syncBox = await Hive.openBox(_syncBoxName);
      await syncBox.put(_syncMetadataKey, metadata);

      // Save remotely
      await FirebaseService.firestore
          .collection('user_sync_metadata')
          .doc(userId)
          .set(metadata, SetOptions(merge: true));

    } catch (e) {
      print('[USER_SYNC] Failed to update sync metadata: $e');
    }
  }

  /// Get sync metadata
  static Future<Map<String, dynamic>?> _getSyncMetadata(String userId) async {
    try {
      final syncBox = await Hive.openBox(_syncBoxName);
      return syncBox.get(_syncMetadataKey) as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// Start remote change listener
  static void _startRemoteChangeListener(String userId) {
    // Implementation for listening to remote changes
    // This would typically use Firestore listeners
  }

  /// Stop remote change listener
  static Future<void> _stopRemoteChangeListener() async {
    // Implementation for stopping remote change listeners
  }

  /// Clear local sync data
  static Future<void> _clearLocalSyncData() async {
    try {
      final syncBox = await Hive.openBox(_syncBoxName);
      await syncBox.clear();
    } catch (e) {
      print('[USER_SYNC] Failed to clear local sync data: $e');
    }
  }

  /// Get device ID
  static Future<String> _getDeviceId() async {
    try {
      // This would typically use device_info_plus
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      return 'device_${timestamp.substring(timestamp.length - 8)}';
    } catch (e) {
      return 'unknown_device';
    }
  }

  /// Check if device is online
  static Future<bool> _isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult.any((result) => result != ConnectivityResult.none);
    } catch (e) {
      return false;
    }
  }

  /// Emit sync event
  static void _emitSyncEvent(SyncEventType type, String message) {
    final event = SyncEvent(
      type: type,
      message: message,
      timestamp: DateTime.now(),
    );

    if (!_syncEventController.isClosed) {
      _syncEventController.add(event);
    }

    // Log to auth event logger
    ComprehensiveAuthService.logAuthEvent(
      AuthEventType.syncEvent,
      message,
    );
  }

  /// Get sync event stream
  static Stream<SyncEvent> get syncEventStream => _syncEventController.stream;

  /// Force synchronization
  static Future<SyncResult> forceSync() async {
    return await _performFullSync();
  }

  /// Get sync status
  static Future<Map<String, dynamic>> getSyncStatus(String userId) async {
    try {
      final metadata = await _getSyncMetadata(userId);
      final syncBox = await Hive.openBox(_syncBoxName);
      final pendingChanges = syncBox.get(_pendingChangesKey) as Map<String, dynamic>? ?? {};
      final userChanges = pendingChanges[userId] as List<dynamic>? ?? [];

      return {
        'lastSync': metadata?['lastSync'],
        'deviceId': metadata?['deviceId'],
        'pendingChangesCount': userChanges.length,
        'isOnline': await _isOnline(),
      };

    } catch (e) {
      return {
        'error': e.toString(),
        'isOnline': await _isOnline(),
      };
    }
  }

  /// Dispose resources
  static void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncEventController.close();
    print('[USER_SYNC] User synchronization service disposed');
  }
}

/// Sync Event Types
enum SyncEventType {
  userAuthenticated,
  userSignedOut,
  syncStarted,
  syncCompleted,
  syncFailed,
  conflictDetected,
  conflictResolved,
}

/// Sync Event
class SyncEvent {
  final SyncEventType type;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  SyncEvent({
    required this.type,
    required this.message,
    required this.timestamp,
    this.metadata,
  });
}

/// Sync Result
class SyncResult {
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;

  SyncResult({
    required this.success,
    this.error,
    this.data,
  });
}