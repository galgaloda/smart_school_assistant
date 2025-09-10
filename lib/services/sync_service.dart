import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:workmanager/workmanager.dart'; // Temporarily disabled
import '../models.dart';
import 'firebase_service.dart';

/// Sync status enumeration
enum SyncStatus {
  idle,
  syncing,
  success,
  error,
}

/// Sync operation types
enum SyncOperation {
  push, // Local to cloud
  pull, // Cloud to local
  bidirectional, // Both directions
}

/// Sync service for managing data synchronization between local storage and Firebase
class SyncService {
  static const String _syncStatusBoxName = 'sync_status';
  static const String _lastSyncKey = 'last_sync_timestamp';
  static const String _syncInProgressKey = 'sync_in_progress';

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize sync service
  static Future<void> initialize() async {
    await Hive.openBox(_syncStatusBoxName);

    // Initialize WorkManager for background sync - Temporarily disabled
    // await _initializeWorkManager();
  }

  /// Initialize WorkManager for background sync - Temporarily disabled
  /*
  static Future<void> _initializeWorkManager() async {
    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false, // Set to true for debugging
      );

      // Register the background sync task
      await Workmanager().registerPeriodicTask(
        'background_sync_task',
        'performBackgroundSync',
        frequency: const Duration(hours: 1), // Sync every hour
        constraints: Constraints(
          networkType: NetworkType.connected, // Only run when connected
          requiresBatteryNotLow: true, // Don't drain battery
          requiresDeviceIdle: false, // Can run when device is active
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 5),
      );
    } catch (e) {
      print('Failed to initialize WorkManager: $e');
    }
  }
  */

  /// Callback dispatcher for WorkManager - Temporarily disabled
  /*
  @pragma('vm:entry-point')
  static void callbackDispatcher() {
    Workmanager().executeTask((task, inputData) async {
      try {
        switch (task) {
          case 'performBackgroundSync':
            return await _performBackgroundSync();
          default:
            return false;
        }
      } catch (e) {
        print('Background sync failed: $e');
        return false;
      }
    });
  }
  */

  /// Perform background sync operation - Temporarily disabled
  /*
  static Future<bool> _performBackgroundSync() async {
    try {
      // Initialize Hive for background task
      await Hive.initFlutter();
      await Hive.openBox(_syncStatusBoxName);

      // Check if user is authenticated
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) {
        return false; // Skip sync if not authenticated
      }

      // Check connectivity
      if (!await isOnline()) {
        return false; // Skip if offline
      }

      // Check if sync is already in progress
      if (isSyncInProgress()) {
        return false; // Skip if already syncing
      }

      await setSyncInProgress(true);
      await setSyncStatus(SyncStatus.syncing);

      try {
        // Perform the actual sync
        final result = await performFullSync();

        await setSyncStatus(result.success ? SyncStatus.success : SyncStatus.error);
        await setLastSyncTime(DateTime.now());

        return result.success;
      } finally {
        await setSyncInProgress(false);
      }
    } catch (e) {
      await setSyncStatus(SyncStatus.error);
      print('Background sync error: $e');
      return false;
    }
  }
  */

  /// Check if device is online
  static Future<bool> isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final isConnected = connectivityResult != ConnectivityResult.none;
      print('[DEBUG] Sync Connectivity - Result: $connectivityResult, IsOnline: $isConnected');
      return isConnected;
    } catch (e) {
      print('[DEBUG] Sync Connectivity - Error checking connectivity: $e');
      // Assume online if we can't check connectivity
      return true;
    }
  }

  /// Test sync functionality and return diagnostic information
  static Future<Map<String, dynamic>> testSyncConnection() async {
    final diagnostics = <String, dynamic>{};

    try {
      // Test connectivity
      diagnostics['connectivity'] = await isOnline();

      // Test authentication
      final currentUser = FirebaseService.currentUser;
      diagnostics['authenticated'] = currentUser != null;
      diagnostics['userId'] = currentUser?.uid;
      diagnostics['userEmail'] = currentUser?.email;

      // Test Firestore access
      if (currentUser != null) {
        try {
          final userDoc = _firestore.collection('users').doc(currentUser.uid);
          final docSnapshot = await userDoc.get();
          diagnostics['firestore_accessible'] = true;
          diagnostics['user_document_exists'] = docSnapshot.exists;
        } catch (e) {
          diagnostics['firestore_accessible'] = false;
          diagnostics['firestore_error'] = e.toString();
        }
      }

      // Test Hive boxes
      final boxNames = [
        'students', 'teachers', 'subjects', 'class_sections',
        'timetable_entries', 'attendance_records', 'scores',
        'assessments', 'semesters', 'inventory_items', 'data_records'
      ];

      final hiveStatus = <String, bool>{};
      for (final boxName in boxNames) {
        try {
          final box = Hive.box(boxName);
          hiveStatus[boxName] = box.isOpen;
        } catch (e) {
          hiveStatus[boxName] = false;
        }
      }
      diagnostics['hive_boxes'] = hiveStatus;

      // Test sync status
      diagnostics['sync_in_progress'] = isSyncInProgress();
      diagnostics['last_sync_time'] = getLastSyncTime()?.toIso8601String();
      diagnostics['sync_status'] = getSyncStatus().toString();

      diagnostics['overall_status'] = 'diagnostic_completed';

    } catch (e) {
      diagnostics['overall_status'] = 'diagnostic_failed';
      diagnostics['error'] = e.toString();
    }

    return diagnostics;
  }

  /// Get current sync status
  static SyncStatus getSyncStatus() {
    final box = Hive.box(_syncStatusBoxName);
    final statusString = box.get('current_status', defaultValue: 'idle');
    switch (statusString) {
      case 'syncing':
        return SyncStatus.syncing;
      case 'success':
        return SyncStatus.success;
      case 'error':
        return SyncStatus.error;
      default:
        return SyncStatus.idle;
    }
  }

  /// Set sync status
  static Future<void> setSyncStatus(SyncStatus status) async {
    final box = Hive.box(_syncStatusBoxName);
    String statusString;
    switch (status) {
      case SyncStatus.syncing:
        statusString = 'syncing';
        break;
      case SyncStatus.success:
        statusString = 'success';
        break;
      case SyncStatus.error:
        statusString = 'error';
        break;
      default:
        statusString = 'idle';
    }
    await box.put('current_status', statusString);
  }

  /// Get last sync timestamp
  static DateTime? getLastSyncTime() {
    final box = Hive.box(_syncStatusBoxName);
    final timestamp = box.get(_lastSyncKey);
    if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Set last sync timestamp
  static Future<void> setLastSyncTime(DateTime timestamp) async {
    final box = Hive.box(_syncStatusBoxName);
    await box.put(_lastSyncKey, timestamp.millisecondsSinceEpoch);
  }

  /// Check if sync is currently in progress
  static bool isSyncInProgress() {
    final box = Hive.box(_syncStatusBoxName);
    return box.get(_syncInProgressKey, defaultValue: false);
  }

  /// Set sync in progress flag
  static Future<void> setSyncInProgress(bool inProgress) async {
    final box = Hive.box(_syncStatusBoxName);
    await box.put(_syncInProgressKey, inProgress);
  }

  /// Background sync settings - Temporarily disabled
  /*
  static const String _backgroundSyncEnabledKey = 'background_sync_enabled';
  static const String _syncIntervalKey = 'sync_interval_hours';
  static const String _wifiOnlyKey = 'wifi_only_sync';
  static const String _batteryOptimizationKey = 'battery_optimization';

  /// Check if background sync is enabled
  static bool isBackgroundSyncEnabled() {
    final box = Hive.box(_syncStatusBoxName);
    return box.get(_backgroundSyncEnabledKey, defaultValue: true);
  }

  /// Enable or disable background sync
  static Future<void> setBackgroundSyncEnabled(bool enabled) async {
    final box = Hive.box(_syncStatusBoxName);
    await box.put(_backgroundSyncEnabledKey, enabled);

    if (enabled) {
      await _scheduleBackgroundSync();
    } else {
      await _cancelBackgroundSync();
    }
  }
  */

  /// Get sync interval in hours - Temporarily disabled
  /*
  static int getSyncIntervalHours() {
    final box = Hive.box(_syncStatusBoxName);
    return box.get(_syncIntervalKey, defaultValue: 1);
  }

  /// Set sync interval in hours
  static Future<void> setSyncIntervalHours(int hours) async {
    final box = Hive.box(_syncStatusBoxName);
    await box.put(_syncIntervalKey, hours);

    if (isBackgroundSyncEnabled()) {
      await _rescheduleBackgroundSync();
    }
  }

  /// Check if sync should only run on WiFi
  static bool isWifiOnlySync() {
    final box = Hive.box(_syncStatusBoxName);
    return box.get(_wifiOnlyKey, defaultValue: false);
  }

  /// Set WiFi-only sync preference
  static Future<void> setWifiOnlySync(bool wifiOnly) async {
    final box = Hive.box(_syncStatusBoxName);
    await box.put(_wifiOnlyKey, wifiOnly);

    if (isBackgroundSyncEnabled()) {
      await _rescheduleBackgroundSync();
    }
  }

  /// Check if battery optimization is enabled
  static bool isBatteryOptimizationEnabled() {
    final box = Hive.box(_syncStatusBoxName);
    return box.get(_batteryOptimizationKey, defaultValue: true);
  }

  /// Set battery optimization preference
  static Future<void> setBatteryOptimizationEnabled(bool enabled) async {
    final box = Hive.box(_syncStatusBoxName);
    await box.put(_batteryOptimizationKey, enabled);

    if (isBackgroundSyncEnabled()) {
      await _rescheduleBackgroundSync();
    }
  }
  */

  /// Schedule background sync task - Temporarily disabled
  /*
  static Future<void> _scheduleBackgroundSync() async {
    try {
      final interval = getSyncIntervalHours();
      final wifiOnly = isWifiOnlySync();
      final batteryOptimization = isBatteryOptimizationEnabled();

      await Workmanager().registerPeriodicTask(
        'background_sync_task',
        'performBackgroundSync',
        frequency: Duration(hours: interval),
        constraints: Constraints(
          networkType: wifiOnly ? NetworkType.unmetered : NetworkType.connected,
          requiresBatteryNotLow: batteryOptimization,
          requiresDeviceIdle: false,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
        backoffPolicy: BackoffPolicy.exponential,
        backoffPolicyDelay: const Duration(minutes: 5),
      );
    } catch (e) {
      print('Failed to schedule background sync: $e');
    }
  }

  /// Cancel background sync task
  static Future<void> _cancelBackgroundSync() async {
    try {
      await Workmanager().cancelByUniqueName('background_sync_task');
    } catch (e) {
      print('Failed to cancel background sync: $e');
    }
  }

  /// Reschedule background sync with new settings
  static Future<void> _rescheduleBackgroundSync() async {
    await _cancelBackgroundSync();
    await _scheduleBackgroundSync();
  }

  /// Force immediate background sync (for testing)
  static Future<void> forceBackgroundSync() async {
    try {
      await Workmanager().registerOneOffTask(
        'force_background_sync',
        'performBackgroundSync',
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );
    } catch (e) {
      print('Failed to force background sync: $e');
    }
  }

  /// Get background sync statistics
  static Future<Map<String, dynamic>> getBackgroundSyncStats() async {
    final box = Hive.box(_syncStatusBoxName);

    return {
      'enabled': isBackgroundSyncEnabled(),
      'interval_hours': getSyncIntervalHours(),
      'wifi_only': isWifiOnlySync(),
      'battery_optimization': isBatteryOptimizationEnabled(),
      'last_sync': getLastSyncTime()?.toIso8601String(),
      'sync_in_progress': isSyncInProgress(),
    };
  }
  */

  /// Perform full synchronization (bidirectional)
  static Future<SyncResult> performFullSync() async {
    print('[DEBUG] Sync - Starting full sync operation');

    // Check connectivity
    final isOnline = await SyncService.isOnline();
    if (!isOnline) {
      print('[DEBUG] Sync - No internet connection');
      return SyncResult(
        success: false,
        message: 'No internet connection available. Please check your network and try again.',
        operation: SyncOperation.bidirectional,
      );
    }

    // Check if sync is already in progress
    if (isSyncInProgress()) {
      print('[DEBUG] Sync - Sync already in progress');
      return SyncResult(
        success: false,
        message: 'Sync already in progress. Please wait for the current sync to complete.',
        operation: SyncOperation.bidirectional,
      );
    }

    // Check authentication
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      print('[DEBUG] Sync - User not authenticated');
      return SyncResult(
        success: false,
        message: 'User not authenticated. Please sign in and try again.',
        operation: SyncOperation.bidirectional,
      );
    }

    await setSyncInProgress(true);
    await setSyncStatus(SyncStatus.syncing);

    try {
      print('[DEBUG] Sync - Beginning push operation');
      // First push local changes to cloud
      final pushResult = await _pushLocalChangesToCloud();

      print('[DEBUG] Sync - Beginning pull operation');
      // Then pull cloud changes to local
      final pullResult = await _pullCloudChangesToLocal();

      final success = pushResult.success && pullResult.success;
      final message = success
          ? 'Sync completed successfully'
          : 'Sync completed with some issues. Check details for more information.';

      await setSyncStatus(success ? SyncStatus.success : SyncStatus.error);
      await setLastSyncTime(DateTime.now());

      // Combine conflicts from both operations
      final allConflicts = <String>[];
      if (pushResult.conflicts != null) {
        allConflicts.addAll(pushResult.conflicts!);
      }
      if (pullResult.conflicts != null) {
        allConflicts.addAll(pullResult.conflicts!);
      }

      print('[DEBUG] Sync - Full sync completed. Success: $success, Message: $message');

      return SyncResult(
        success: success,
        message: message,
        operation: SyncOperation.bidirectional,
        pushResult: pushResult,
        pullResult: pullResult,
        conflicts: allConflicts.isNotEmpty ? allConflicts : null,
      );
    } catch (e) {
      print('[DEBUG] Sync - Critical error during sync: $e');
      await setSyncStatus(SyncStatus.error);
      return SyncResult(
        success: false,
        message: 'Sync failed due to a critical error: $e. Please try again.',
        operation: SyncOperation.bidirectional,
      );
    } finally {
      await setSyncInProgress(false);
    }
  }

  /// Push local changes to cloud
  static Future<SyncResult> pushToCloud() async {
    if (!await isOnline()) {
      return SyncResult(
        success: false,
        message: 'No internet connection available',
        operation: SyncOperation.push,
      );
    }

    await setSyncInProgress(true);
    await setSyncStatus(SyncStatus.syncing);

    try {
      final result = await _pushLocalChangesToCloud();
      await setSyncStatus(result.success ? SyncStatus.success : SyncStatus.error);
      if (result.success) {
        await setLastSyncTime(DateTime.now());
      }
      return result;
    } catch (e) {
      await setSyncStatus(SyncStatus.error);
      return SyncResult(
        success: false,
        message: 'Push failed: $e',
        operation: SyncOperation.push,
      );
    } finally {
      await setSyncInProgress(false);
    }
  }

  /// Pull cloud changes to local
  static Future<SyncResult> pullFromCloud() async {
    if (!await isOnline()) {
      return SyncResult(
        success: false,
        message: 'No internet connection available',
        operation: SyncOperation.pull,
      );
    }

    await setSyncInProgress(true);
    await setSyncStatus(SyncStatus.syncing);

    try {
      final result = await _pullCloudChangesToLocal();
      await setSyncStatus(result.success ? SyncStatus.success : SyncStatus.error);
      if (result.success) {
        await setLastSyncTime(DateTime.now());
      }
      return result;
    } catch (e) {
      await setSyncStatus(SyncStatus.error);
      return SyncResult(
        success: false,
        message: 'Pull failed: $e',
        operation: SyncOperation.pull,
      );
    } finally {
      await setSyncInProgress(false);
    }
  }

  /// Push local changes to cloud (internal implementation)
  static Future<SyncResult> _pushLocalChangesToCloud() async {
    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) {
        print('[DEBUG] Sync Push - User not authenticated');
        return SyncResult(
          success: false,
          message: 'User not authenticated. Please sign in again.',
          operation: SyncOperation.push,
        );
      }

      final userId = currentUser.uid;
      final userDoc = _firestore.collection('users').doc(userId);
      print('[DEBUG] Sync Push - Starting for user: $userId, userDoc path: ${userDoc.path}');

      // Verify user document exists and is accessible
      try {
        await userDoc.get();
        print('[DEBUG] Sync Push - User document is accessible');
      } catch (e) {
        print('[DEBUG] Sync Push - Error accessing user document: $e');
        return SyncResult(
          success: false,
          message: 'Cannot access user data in cloud. Check your internet connection and permissions.',
          operation: SyncOperation.push,
        );
      }

      // Sync all data types with individual error handling
      final results = <SyncResult>[];
      final syncOperations = [
        () => _syncStudentsToCloud(userDoc),
        () => _syncTeachersToCloud(userDoc),
        () => _syncSubjectsToCloud(userDoc),
        () => _syncClassesToCloud(userDoc),
        () => _syncTimetableToCloud(userDoc),
        () => _syncAttendanceToCloud(userDoc),
        () => _syncScoresToCloud(userDoc),
        () => _syncAssessmentsToCloud(userDoc),
        () => _syncSemestersToCloud(userDoc),
        () => _syncInventoryToCloud(userDoc),
        () => _syncDataRecordsToCloud(userDoc),
      ];

      for (final operation in syncOperations) {
        try {
          final result = await operation();
          results.add(result);
        } catch (e) {
          print('[DEBUG] Sync Push - Error in sync operation: $e');
          results.add(SyncResult(
            success: false,
            message: 'Sync operation failed: $e',
            operation: SyncOperation.push,
          ));
        }
      }

      final successCount = results.where((result) => result.success).length;
      final totalCount = results.length;

      final message = successCount == totalCount
          ? 'Successfully synced all data to cloud'
          : 'Partially synced data to cloud ($successCount/$totalCount successful)';

      return SyncResult(
        success: successCount > 0, // Consider partial success as overall success
        message: message,
        operation: SyncOperation.push,
        syncedItems: _combineSyncedItems(results),
      );
    } catch (e) {
      print('[DEBUG] Sync Push - Critical error: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed due to critical error: $e',
        operation: SyncOperation.push,
      );
    }
  }

  /// Pull cloud changes to local (internal implementation)
  static Future<SyncResult> _pullCloudChangesToLocal() async {
    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) {
        print('[DEBUG] Sync Pull - User not authenticated');
        return SyncResult(
          success: false,
          message: 'User not authenticated. Please sign in again.',
          operation: SyncOperation.pull,
        );
      }

      final userId = currentUser.uid;
      final userDoc = _firestore.collection('users').doc(userId);
      print('[DEBUG] Sync Pull - Starting for user: $userId, userDoc path: ${userDoc.path}');

      // Verify user document exists and is accessible
      try {
        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          print('[DEBUG] Sync Pull - User document does not exist in cloud');
          return SyncResult(
            success: false,
            message: 'User data not found in cloud. This may be your first sync.',
            operation: SyncOperation.pull,
          );
        }
        print('[DEBUG] Sync Pull - User document exists and is accessible');
      } catch (e) {
        print('[DEBUG] Sync Pull - Error accessing user document: $e');
        return SyncResult(
          success: false,
          message: 'Cannot access user data in cloud. Check your internet connection and permissions.',
          operation: SyncOperation.pull,
        );
      }

      // Sync all data types with individual error handling
      final results = <SyncResult>[];
      final syncOperations = [
        () => _syncStudentsFromCloud(userDoc),
        () => _syncTeachersFromCloud(userDoc),
        () => _syncSubjectsFromCloud(userDoc),
        () => _syncClassesFromCloud(userDoc),
        () => _syncTimetableFromCloud(userDoc),
        () => _syncAttendanceFromCloud(userDoc),
        () => _syncScoresFromCloud(userDoc),
        () => _syncAssessmentsFromCloud(userDoc),
        () => _syncSemestersFromCloud(userDoc),
        () => _syncInventoryFromCloud(userDoc),
        () => _syncDataRecordsFromCloud(userDoc),
      ];

      for (final operation in syncOperations) {
        try {
          final result = await operation();
          results.add(result);
        } catch (e) {
          print('[DEBUG] Sync Pull - Error in sync operation: $e');
          results.add(SyncResult(
            success: false,
            message: 'Sync operation failed: $e',
            operation: SyncOperation.pull,
          ));
        }
      }

      final successCount = results.where((result) => result.success).length;
      final totalCount = results.length;

      final message = successCount == totalCount
          ? 'Successfully synced all data from cloud'
          : 'Partially synced data from cloud ($successCount/$totalCount successful)';

      return SyncResult(
        success: successCount > 0, // Consider partial success as overall success
        message: message,
        operation: SyncOperation.pull,
        syncedItems: _combineSyncedItems(results),
      );
    } catch (e) {
      print('[DEBUG] Sync Pull - Critical error: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed due to critical error: $e',
        operation: SyncOperation.pull,
      );
    }
  }

  /// Sync students to cloud
  static Future<SyncResult> _syncStudentsToCloud(DocumentReference userDoc) async {
    return _syncCollectionToCloud<Student>(
      localBox: Hive.box<Student>('students'),
      cloudCollection: userDoc.collection('students'),
      itemType: 'students',
    );
  }

  /// Sync students from cloud
  static Future<SyncResult> _syncStudentsFromCloud(DocumentReference userDoc) async {
    return _syncCollectionFromCloud<Student>(
      localBox: Hive.box<Student>('students'),
      cloudCollection: userDoc.collection('students'),
      itemType: 'students',
      fromJson: (data) => Student(
        id: data['id'],
        fullName: data['fullName'],
        photoPath: data['photoPath'],
        dateOfBirth: DateTime.parse(data['dateOfBirth']),
        gender: data['gender'],
        classSectionId: data['classSectionId'],
        phoneNumber: data['phoneNumber'],
        address: data['address'],
        emergencyContactName: data['emergencyContactName'],
        emergencyContactPhone: data['emergencyContactPhone'],
        email: data['email'],
        enrollmentDate: data['enrollmentDate'] != null ? DateTime.parse(data['enrollmentDate']) : null,
        studentId: data['studentId'],
        grade: data['grade'],
        bloodType: data['bloodType'],
        medicalConditions: data['medicalConditions'],
        nationality: data['nationality'],
        religion: data['religion'],
        isSynced: true,
        lastUpdated: DateTime.now(),
        userId: data['userId'],
        syncId: data['syncId'],
      ),
    );
  }

  /// Generic method to sync collection to cloud
  static Future<SyncResult> _syncCollectionToCloud<T extends HiveObject>({
    required Box<T> localBox,
    required CollectionReference cloudCollection,
    required String itemType,
  }) async {
    try {
      final unsyncedItems = localBox.values.where((item) {
        if (item is Student) return !item.isSynced;
        if (item is Teacher) return !item.isSynced;
        if (item is Subject) return !item.isSynced;
        if (item is ClassSection) return !item.isSynced;
        if (item is TimeTableEntry) return !item.isSynced;
        if (item is AttendanceRecord) return !item.isSynced;
        if (item is Score) return !item.isSynced;
        if (item is Assessment) return !item.isSynced;
        if (item is Semester) return !item.isSynced;
        if (item is InventoryItem) return !item.isSynced;
        if (item is DataRecord) return !item.isSynced;
        if (item is AssessmentScore) return !item.isSynced;
        return false;
      }).toList();

      if (unsyncedItems.isEmpty) {
        print('[DEBUG] Sync Push - No unsynced $itemType items to upload');
        return SyncResult(
          success: true,
          message: 'No $itemType items to sync',
          operation: SyncOperation.push,
        );
      }

      final syncedItems = <String>[];
      final failedItems = <String>[];

      for (final item in unsyncedItems) {
        bool itemSynced = false;
        String? errorMessage;

        // Retry logic - try up to 3 times
        for (int attempt = 1; attempt <= 3 && !itemSynced; attempt++) {
          try {
            final data = _convertHiveObjectToMap(item);
            if (data == null) {
              errorMessage = 'Failed to convert item data';
              break;
            }

            print('[DEBUG] Sync Push - Attempting to write $itemType:${item.key} to ${cloudCollection.path} (attempt $attempt)');
            await cloudCollection.doc(item.key.toString()).set(data, SetOptions(merge: true));
            print('[DEBUG] Sync Push - Successfully wrote $itemType:${item.key}');

            // Mark as synced
            await _markItemAsSynced(item);
            syncedItems.add('$itemType:${item.key}');
            itemSynced = true;

          } catch (e) {
            errorMessage = e.toString();
            print('[DEBUG] Sync Push - Attempt $attempt failed for $itemType:${item.key}: $e');

            // Wait before retry (exponential backoff)
            if (attempt < 3) {
              await Future.delayed(Duration(seconds: attempt));
            }
          }
        }

        if (!itemSynced) {
          failedItems.add('$itemType:${item.key} (error: $errorMessage)');
          print('[DEBUG] Sync Push - Failed to sync $itemType:${item.key} after 3 attempts');
        }
      }

      final success = syncedItems.isNotEmpty;
      final message = success
          ? 'Synced ${syncedItems.length} $itemType to cloud${failedItems.isNotEmpty ? " (${failedItems.length} failed)" : ""}'
          : 'Failed to sync any $itemType items';

      return SyncResult(
        success: success,
        message: message,
        operation: SyncOperation.push,
        syncedItems: syncedItems,
        conflicts: failedItems.isNotEmpty ? failedItems : null,
      );
    } catch (e) {
      print('[DEBUG] Sync Push - Critical error syncing $itemType: $e');
      return SyncResult(
        success: false,
        message: 'Failed to sync $itemType to cloud: $e',
        operation: SyncOperation.push,
      );
    }
  }

  /// Generic method to sync collection from cloud
  static Future<SyncResult> _syncCollectionFromCloud<T extends HiveObject>({
    required Box<T> localBox,
    required CollectionReference cloudCollection,
    required String itemType,
    required T Function(Map<String, dynamic>) fromJson,
  }) async {
    try {
      print('[DEBUG] Sync Pull - Attempting to read from ${cloudCollection.path}');
      final cloudSnapshot = await cloudCollection.get();
      print('[DEBUG] Sync Pull - Successfully read ${cloudSnapshot.docs.length} documents from ${cloudCollection.path}');
      final syncedItems = <String>[];

      for (final doc in cloudSnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final item = fromJson(data);

          // Check if item exists locally
          final existingItem = localBox.get(doc.id);

          if (existingItem == null) {
            // New item from cloud
            await localBox.put(doc.id, item);
            syncedItems.add('$itemType:${doc.id}');
          } else {
            // Item exists, check for conflicts and resolve them
            final localData = _convertHiveObjectToMap(existingItem);
            final cloudData = data;

            if (localData == null) {
              // Failed to convert local data, use cloud version
              await localBox.put(doc.id, item);
              syncedItems.add('$itemType:${doc.id} (local data conversion failed)');
              continue;
            }

            // Check if there's a conflict
            if (ConflictResolver.hasConflict(localData, cloudData)) {
              // Get recommended conflict resolution strategy
              final strategy = ConflictResolver.getRecommendedStrategy(itemType);

              // Resolve the conflict
              final resolution = await ConflictResolver.resolveConflict(
                itemType,
                localData,
                cloudData,
                strategy,
              );

              if (resolution.resolved && resolution.resolvedData != null) {
                // Create resolved item
                final resolvedItem = fromJson(resolution.resolvedData!);
                await localBox.put(doc.id, resolvedItem);
                syncedItems.add('$itemType:${doc.id} (resolved: ${resolution.strategy})');
              } else {
                // If resolution failed, use cloud version as fallback
                await localBox.put(doc.id, item);
                syncedItems.add('$itemType:${doc.id} (fallback to cloud)');
              }
            } else {
              // No conflict, check timestamps
              final cloudLastUpdated = data['lastUpdated'] != null
                  ? DateTime.parse(data['lastUpdated'])
                  : DateTime.fromMillisecondsSinceEpoch(0);

              DateTime? localLastUpdated;
              if (existingItem is Student) {
                localLastUpdated = existingItem.lastUpdated;
              } else if (existingItem is Teacher) localLastUpdated = existingItem.lastUpdated;
              else if (existingItem is Subject) localLastUpdated = existingItem.lastUpdated;
              else if (existingItem is ClassSection) localLastUpdated = existingItem.lastUpdated;
              else if (existingItem is TimeTableEntry) localLastUpdated = existingItem.lastUpdated;
              else if (existingItem is AttendanceRecord) localLastUpdated = existingItem.lastUpdated;
              else if (existingItem is Score) localLastUpdated = existingItem.lastUpdated;
              else if (existingItem is Assessment) localLastUpdated = existingItem.lastUpdated;
              else if (existingItem is Semester) localLastUpdated = existingItem.lastUpdated;
              else if (existingItem is InventoryItem) localLastUpdated = existingItem.lastUpdated;
              else if (existingItem is DataRecord) localLastUpdated = existingItem.lastUpdated;
              else if (existingItem is AssessmentScore) localLastUpdated = existingItem.lastUpdated;

              if (localLastUpdated == null || cloudLastUpdated.isAfter(localLastUpdated)) {
                // Cloud version is newer, update local
                await localBox.put(doc.id, item);
                syncedItems.add('$itemType:${doc.id}');
              }
            }
          }
        } catch (e) {
          print('Error syncing $itemType item ${doc.id}: $e');
        }
      }

      return SyncResult(
        success: true,
        message: 'Synced ${syncedItems.length} $itemType from cloud',
        operation: SyncOperation.pull,
        syncedItems: syncedItems,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Failed to sync $itemType from cloud: $e',
        operation: SyncOperation.pull,
      );
    }
  }

  /// Helper method to combine synced items from multiple results
  static List<String> _combineSyncedItems(List<SyncResult> results) {
    final combined = <String>[];
    for (final result in results) {
      if (result.syncedItems != null) {
        combined.addAll(result.syncedItems!.cast<String>());
      }
    }
    return combined;
  }

  /// Mark a Hive item as synced
  static Future<void> _markItemAsSynced(HiveObject item) async {
    final now = DateTime.now();

    if (item is Student) {
      item.isSynced = true;
      item.lastUpdated = now;
      await item.save();
    } else if (item is Teacher) {
      item.isSynced = true;
      item.lastUpdated = now;
      await item.save();
    } else if (item is Subject) {
      item.isSynced = true;
      item.lastUpdated = now;
      await item.save();
    } else if (item is ClassSection) {
      item.isSynced = true;
      item.lastUpdated = now;
      await item.save();
    } else if (item is TimeTableEntry) {
      item.isSynced = true;
      item.lastUpdated = now;
      await item.save();
    } else if (item is AttendanceRecord) {
      item.isSynced = true;
      item.lastUpdated = now;
      await item.save();
    } else if (item is Score) {
      item.isSynced = true;
      item.lastUpdated = now;
      await item.save();
    } else if (item is Assessment) {
      item.isSynced = true;
      item.lastUpdated = now;
      await item.save();
    } else if (item is Semester) {
      item.isSynced = true;
      item.lastUpdated = now;
      await item.save();
    } else if (item is InventoryItem) {
      item.isSynced = true;
      item.lastUpdated = now;
      await item.save();
    } else if (item is DataRecord) {
      item.isSynced = true;
      item.lastUpdated = now;
      await item.save();
    } else if (item is AssessmentScore) {
      item.isSynced = true;
      item.lastUpdated = now;
      await item.save();
    }
  }

  /// Convert Hive object to map for Firestore
  static Map<String, dynamic>? _convertHiveObjectToMap(HiveObject item) {
    try {
      if (item is Student) {
        return {
          'id': item.id ?? '',
          'fullName': item.fullName ?? '',
          'photoPath': item.photoPath,
          'dateOfBirth': item.dateOfBirth.toIso8601String(),
          'gender': item.gender ?? '',
          'classSectionId': item.classSectionId ?? '',
          'phoneNumber': item.phoneNumber,
          'address': item.address,
          'emergencyContactName': item.emergencyContactName,
          'emergencyContactPhone': item.emergencyContactPhone,
          'email': item.email,
          'enrollmentDate': item.enrollmentDate?.toIso8601String(),
          'studentId': item.studentId,
          'grade': item.grade,
          'bloodType': item.bloodType,
          'medicalConditions': item.medicalConditions,
          'nationality': item.nationality,
          'religion': item.religion,
          'isSynced': item.isSynced ?? false,
          'lastUpdated': item.lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'userId': item.userId,
          'syncId': item.syncId,
        };
      } else if (item is Teacher) {
        return {
          'id': item.id ?? '',
          'fullName': item.fullName ?? '',
          'isSynced': item.isSynced ?? false,
          'lastUpdated': item.lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'userId': item.userId,
          'syncId': item.syncId,
        };
      } else if (item is Subject) {
        return {
          'id': item.id ?? '',
          'name': item.name ?? '',
          'teacherId': item.teacherId ?? '',
          'isSynced': item.isSynced ?? false,
          'lastUpdated': item.lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'userId': item.userId,
          'syncId': item.syncId,
        };
      } else if (item is ClassSection) {
        return {
          'id': item.id ?? '',
          'name': item.name ?? '',
          'isSynced': item.isSynced ?? false,
          'lastUpdated': item.lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'userId': item.userId,
          'syncId': item.syncId,
        };
      } else if (item is TimeTableEntry) {
        return {
          'dayOfWeek': item.dayOfWeek ?? '',
          'period': item.period ?? '',
          'subjectId': item.subjectId ?? '',
          'classSectionId': item.classSectionId ?? '',
          'isSynced': item.isSynced ?? false,
          'lastUpdated': item.lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'userId': item.userId,
          'syncId': item.syncId,
        };
      } else if (item is AttendanceRecord) {
        return {
          'studentId': item.studentId ?? '',
          'date': item.date.toIso8601String(),
          'status': item.status ?? '',
          'isSynced': item.isSynced ?? false,
          'lastUpdated': item.lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'userId': item.userId,
          'syncId': item.syncId,
        };
      } else if (item is Score) {
        return {
          'studentId': item.studentId ?? '',
          'subjectId': item.subjectId ?? '',
          'assessmentType': item.assessmentType ?? '',
          'marks': item.marks ?? 0.0,
          'date': item.date.toIso8601String(),
          'isSynced': item.isSynced ?? false,
          'lastUpdated': item.lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'userId': item.userId,
          'syncId': item.syncId,
        };
      } else if (item is Assessment) {
        return {
          'id': item.id ?? '',
          'name': item.name ?? '',
          'subjectId': item.subjectId ?? '',
          'classSectionId': item.classSectionId ?? '',
          'semesterId': item.semesterId ?? '',
          'weight': item.weight ?? 0.0,
          'maxMarks': item.maxMarks ?? 0.0,
          'dueDate': item.dueDate.toIso8601String(),
          'description': item.description ?? '',
          'isSynced': item.isSynced ?? false,
          'lastUpdated': item.lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'userId': item.userId,
          'syncId': item.syncId,
        };
      } else if (item is Semester) {
        return {
          'id': item.id ?? '',
          'name': item.name ?? '',
          'academicYear': item.academicYear ?? '',
          'startDate': item.startDate.toIso8601String(),
          'endDate': item.endDate.toIso8601String(),
          'isActive': item.isActive ?? false,
          'isSynced': item.isSynced ?? false,
          'lastUpdated': item.lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'userId': item.userId,
          'syncId': item.syncId,
        };
      } else if (item is InventoryItem) {
        return {
          'id': item.id ?? '',
          'name': item.name ?? '',
          'quantity': item.quantity ?? 0,
          'type': item.type ?? '',
          'condition': item.condition ?? '',
          'description': item.description ?? '',
          'dateAdded': item.dateAdded.toIso8601String(),
          'isSynced': item.isSynced ?? false,
          'lastUpdated': item.lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'userId': item.userId,
          'syncId': item.syncId,
        };
      } else if (item is DataRecord) {
        return {
          'id': item.id ?? '',
          'title': item.title ?? '',
          'category': item.category ?? '',
          'content': item.content ?? '',
          'attachmentPath': item.attachmentPath,
          'priority': item.priority ?? '',
          'status': item.status ?? '',
          'dateCreated': item.dateCreated.toIso8601String(),
          'lastModified': item.lastModified?.toIso8601String(),
          'createdBy': item.createdBy ?? '',
          'isSynced': item.isSynced ?? false,
          'lastUpdated': item.lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'userId': item.userId,
          'syncId': item.syncId,
        };
      } else if (item is AssessmentScore) {
        return {
          'id': item.id ?? '',
          'studentId': item.studentId ?? '',
          'assessmentId': item.assessmentId ?? '',
          'marksObtained': item.marksObtained ?? 0.0,
          'dateRecorded': item.dateRecorded.toIso8601String(),
          'recordedBy': item.recordedBy ?? '',
          'isSynced': item.isSynced ?? false,
          'lastUpdated': item.lastUpdated?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'userId': item.userId,
          'syncId': item.syncId,
        };
      }

      print('[DEBUG] Sync - Unsupported HiveObject type: ${item.runtimeType}');
      return null;
    } catch (e) {
      print('[DEBUG] Sync - Error converting ${item.runtimeType} to map: $e');
      return null;
    }
  }

  /// Sync teachers to cloud
  static Future<SyncResult> _syncTeachersToCloud(DocumentReference userDoc) async {
    return _syncCollectionToCloud<Teacher>(
      localBox: Hive.box<Teacher>('teachers'),
      cloudCollection: userDoc.collection('teachers'),
      itemType: 'teachers',
    );
  }

  /// Sync teachers from cloud
  static Future<SyncResult> _syncTeachersFromCloud(DocumentReference userDoc) async {
    return _syncCollectionFromCloud<Teacher>(
      localBox: Hive.box<Teacher>('teachers'),
      cloudCollection: userDoc.collection('teachers'),
      itemType: 'teachers',
      fromJson: (data) => Teacher(
        id: data['id'],
        fullName: data['fullName'],
        isSynced: true,
        lastUpdated: DateTime.now(),
        userId: data['userId'],
        syncId: data['syncId'],
      ),
    );
  }

  /// Sync subjects to cloud
  static Future<SyncResult> _syncSubjectsToCloud(DocumentReference userDoc) async {
    return _syncCollectionToCloud<Subject>(
      localBox: Hive.box<Subject>('subjects'),
      cloudCollection: userDoc.collection('subjects'),
      itemType: 'subjects',
    );
  }

  /// Sync subjects from cloud
  static Future<SyncResult> _syncSubjectsFromCloud(DocumentReference userDoc) async {
    return _syncCollectionFromCloud<Subject>(
      localBox: Hive.box<Subject>('subjects'),
      cloudCollection: userDoc.collection('subjects'),
      itemType: 'subjects',
      fromJson: (data) => Subject(
        id: data['id'],
        name: data['name'],
        teacherId: data['teacherId'],
        isSynced: true,
        lastUpdated: DateTime.now(),
        userId: data['userId'],
        syncId: data['syncId'],
      ),
    );
  }

  /// Sync classes to cloud
  static Future<SyncResult> _syncClassesToCloud(DocumentReference userDoc) async {
    return _syncCollectionToCloud<ClassSection>(
      localBox: Hive.box<ClassSection>('class_sections'),
      cloudCollection: userDoc.collection('class_sections'),
      itemType: 'class_sections',
    );
  }

  /// Sync classes from cloud
  static Future<SyncResult> _syncClassesFromCloud(DocumentReference userDoc) async {
    return _syncCollectionFromCloud<ClassSection>(
      localBox: Hive.box<ClassSection>('class_sections'),
      cloudCollection: userDoc.collection('class_sections'),
      itemType: 'class_sections',
      fromJson: (data) => ClassSection(
        id: data['id'],
        name: data['name'],
        isSynced: true,
        lastUpdated: DateTime.now(),
        userId: data['userId'],
        syncId: data['syncId'],
      ),
    );
  }

  /// Sync timetable to cloud
  static Future<SyncResult> _syncTimetableToCloud(DocumentReference userDoc) async {
    return _syncCollectionToCloud<TimeTableEntry>(
      localBox: Hive.box<TimeTableEntry>('timetable_entries'),
      cloudCollection: userDoc.collection('timetable_entries'),
      itemType: 'timetable_entries',
    );
  }

  /// Sync timetable from cloud
  static Future<SyncResult> _syncTimetableFromCloud(DocumentReference userDoc) async {
    return _syncCollectionFromCloud<TimeTableEntry>(
      localBox: Hive.box<TimeTableEntry>('timetable_entries'),
      cloudCollection: userDoc.collection('timetable_entries'),
      itemType: 'timetable_entries',
      fromJson: (data) => TimeTableEntry(
        dayOfWeek: data['dayOfWeek'],
        period: data['period'],
        subjectId: data['subjectId'],
        classSectionId: data['classSectionId'],
        isSynced: true,
        lastUpdated: DateTime.now(),
        userId: data['userId'],
        syncId: data['syncId'],
      ),
    );
  }

  /// Sync attendance to cloud
  static Future<SyncResult> _syncAttendanceToCloud(DocumentReference userDoc) async {
    return _syncCollectionToCloud<AttendanceRecord>(
      localBox: Hive.box<AttendanceRecord>('attendance_records'),
      cloudCollection: userDoc.collection('attendance_records'),
      itemType: 'attendance_records',
    );
  }

  /// Sync attendance from cloud
  static Future<SyncResult> _syncAttendanceFromCloud(DocumentReference userDoc) async {
    return _syncCollectionFromCloud<AttendanceRecord>(
      localBox: Hive.box<AttendanceRecord>('attendance_records'),
      cloudCollection: userDoc.collection('attendance_records'),
      itemType: 'attendance_records',
      fromJson: (data) => AttendanceRecord(
        studentId: data['studentId'],
        date: DateTime.parse(data['date']),
        status: data['status'],
        isSynced: true,
        lastUpdated: DateTime.now(),
        userId: data['userId'],
        syncId: data['syncId'],
      ),
    );
  }

  /// Sync scores to cloud
  static Future<SyncResult> _syncScoresToCloud(DocumentReference userDoc) async {
    return _syncCollectionToCloud<Score>(
      localBox: Hive.box<Score>('scores'),
      cloudCollection: userDoc.collection('scores'),
      itemType: 'scores',
    );
  }

  /// Sync scores from cloud
  static Future<SyncResult> _syncScoresFromCloud(DocumentReference userDoc) async {
    return _syncCollectionFromCloud<Score>(
      localBox: Hive.box<Score>('scores'),
      cloudCollection: userDoc.collection('scores'),
      itemType: 'scores',
      fromJson: (data) => Score(
        studentId: data['studentId'],
        subjectId: data['subjectId'],
        assessmentType: data['assessmentType'],
        marks: (data['marks'] as num).toDouble(),
        date: DateTime.parse(data['date']),
        isSynced: true,
        lastUpdated: DateTime.now(),
        userId: data['userId'],
        syncId: data['syncId'],
      ),
    );
  }

  /// Sync assessments to cloud
  static Future<SyncResult> _syncAssessmentsToCloud(DocumentReference userDoc) async {
    return _syncCollectionToCloud<Assessment>(
      localBox: Hive.box<Assessment>('assessments'),
      cloudCollection: userDoc.collection('assessments'),
      itemType: 'assessments',
    );
  }

  /// Sync assessments from cloud
  static Future<SyncResult> _syncAssessmentsFromCloud(DocumentReference userDoc) async {
    return _syncCollectionFromCloud<Assessment>(
      localBox: Hive.box<Assessment>('assessments'),
      cloudCollection: userDoc.collection('assessments'),
      itemType: 'assessments',
      fromJson: (data) => Assessment(
        id: data['id'],
        name: data['name'],
        subjectId: data['subjectId'],
        classSectionId: data['classSectionId'],
        semesterId: data['semesterId'],
        weight: (data['weight'] as num).toDouble(),
        maxMarks: (data['maxMarks'] as num).toDouble(),
        dueDate: DateTime.parse(data['dueDate']),
        description: data['description'],
        isSynced: true,
        lastUpdated: DateTime.now(),
        userId: data['userId'],
        syncId: data['syncId'],
      ),
    );
  }

  /// Sync semesters to cloud
  static Future<SyncResult> _syncSemestersToCloud(DocumentReference userDoc) async {
    return _syncCollectionToCloud<Semester>(
      localBox: Hive.box<Semester>('semesters'),
      cloudCollection: userDoc.collection('semesters'),
      itemType: 'semesters',
    );
  }

  /// Sync semesters from cloud
  static Future<SyncResult> _syncSemestersFromCloud(DocumentReference userDoc) async {
    return _syncCollectionFromCloud<Semester>(
      localBox: Hive.box<Semester>('semesters'),
      cloudCollection: userDoc.collection('semesters'),
      itemType: 'semesters',
      fromJson: (data) => Semester(
        id: data['id'],
        name: data['name'],
        academicYear: data['academicYear'],
        startDate: DateTime.parse(data['startDate']),
        endDate: DateTime.parse(data['endDate']),
        isActive: data['isActive'] ?? false,
        isSynced: true,
        lastUpdated: DateTime.now(),
        userId: data['userId'],
        syncId: data['syncId'],
      ),
    );
  }

  /// Sync inventory to cloud
  static Future<SyncResult> _syncInventoryToCloud(DocumentReference userDoc) async {
    return _syncCollectionToCloud<InventoryItem>(
      localBox: Hive.box<InventoryItem>('inventory_items'),
      cloudCollection: userDoc.collection('inventory_items'),
      itemType: 'inventory_items',
    );
  }

  /// Sync inventory from cloud
  static Future<SyncResult> _syncInventoryFromCloud(DocumentReference userDoc) async {
    return _syncCollectionFromCloud<InventoryItem>(
      localBox: Hive.box<InventoryItem>('inventory_items'),
      cloudCollection: userDoc.collection('inventory_items'),
      itemType: 'inventory_items',
      fromJson: (data) => InventoryItem(
        id: data['id'],
        name: data['name'],
        quantity: data['quantity'],
        type: data['type'],
        condition: data['condition'],
        description: data['description'],
        dateAdded: DateTime.parse(data['dateAdded']),
        isSynced: true,
        lastUpdated: DateTime.now(),
        userId: data['userId'],
        syncId: data['syncId'],
      ),
    );
  }

  /// Sync data records to cloud
  static Future<SyncResult> _syncDataRecordsToCloud(DocumentReference userDoc) async {
    return _syncCollectionToCloud<DataRecord>(
      localBox: Hive.box<DataRecord>('data_records'),
      cloudCollection: userDoc.collection('data_records'),
      itemType: 'data_records',
    );
  }

  /// Sync data records from cloud
  static Future<SyncResult> _syncDataRecordsFromCloud(DocumentReference userDoc) async {
    return _syncCollectionFromCloud<DataRecord>(
      localBox: Hive.box<DataRecord>('data_records'),
      cloudCollection: userDoc.collection('data_records'),
      itemType: 'data_records',
      fromJson: (data) => DataRecord(
        id: data['id'],
        title: data['title'],
        category: data['category'],
        content: data['content'],
        attachmentPath: data['attachmentPath'],
        priority: data['priority'],
        status: data['status'],
        dateCreated: DateTime.parse(data['dateCreated']),
        lastModified: data['lastModified'] != null ? DateTime.parse(data['lastModified']) : null,
        createdBy: data['createdBy'],
        isSynced: true,
        lastUpdated: DateTime.now(),
        userId: data['userId'],
        syncId: data['syncId'],
      ),
    );
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final SyncOperation operation;
  final List<String>? syncedItems;
  final List<String>? conflicts;
  final SyncResult? pushResult;
  final SyncResult? pullResult;
  final DateTime timestamp;

  SyncResult({
    required this.success,
    required this.message,
    required this.operation,
    this.syncedItems,
    this.conflicts,
    this.pushResult,
    this.pullResult,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'SyncResult(success: $success, message: $message, operation: $operation, syncedItems: ${syncedItems?.length ?? 0}, conflicts: ${conflicts?.length ?? 0})';
  }
}

/// Conflict resolution strategies
enum ConflictStrategy {
  localWins,
  cloudWins,
  merge,
  askUser,
}

/// Conflict resolution result
class ConflictResolutionResult {
  final bool resolved;
  final Map<String, dynamic>? resolvedData;
  final String strategy;
  final String? error;

  ConflictResolutionResult({
    required this.resolved,
    this.resolvedData,
    required this.strategy,
    this.error,
  });
}

/// Advanced conflict resolution for complex data types
class ConflictResolver {
  /// Resolve conflict between local and cloud data
  static Future<ConflictResolutionResult> resolveConflict<T>(
    String collectionName,
    Map<String, dynamic> localData,
    Map<String, dynamic> cloudData,
    ConflictStrategy strategy,
  ) async {
    try {
      switch (strategy) {
        case ConflictStrategy.localWins:
          return ConflictResolutionResult(
            resolved: true,
            resolvedData: localData,
            strategy: 'local_wins',
          );
        case ConflictStrategy.cloudWins:
          return ConflictResolutionResult(
            resolved: true,
            resolvedData: cloudData,
            strategy: 'cloud_wins',
          );
        case ConflictStrategy.merge:
          return ConflictResolutionResult(
            resolved: true,
            resolvedData: _mergeData(localData, cloudData, collectionName),
            strategy: 'merge',
          );
        case ConflictStrategy.askUser:
          // For now, default to merge strategy if user interaction is not available
          final merged = _mergeData(localData, cloudData, collectionName);
          return ConflictResolutionResult(
            resolved: true,
            resolvedData: merged,
            strategy: 'merge_fallback',
          );
      }
    } catch (e) {
      return ConflictResolutionResult(
        resolved: false,
        strategy: 'error',
        error: e.toString(),
      );
    }
  }

  /// Merge data from local and cloud versions
  static Map<String, dynamic> _mergeData(
    Map<String, dynamic> localData,
    Map<String, dynamic> cloudData,
    String collectionName,
  ) {
    final merged = Map<String, dynamic>.from(cloudData);

    // For different data types, apply different merge strategies
    switch (collectionName) {
      case 'students':
        return _mergeStudentData(localData, cloudData);
      case 'teachers':
        return _mergeTeacherData(localData, cloudData);
      case 'subjects':
        return _mergeSubjectData(localData, cloudData);
      case 'class_sections':
        return _mergeClassData(localData, cloudData);
      case 'timetable_entries':
        return _mergeTimetableData(localData, cloudData);
      case 'attendance_records':
        return _mergeAttendanceData(localData, cloudData);
      case 'scores':
        return _mergeScoreData(localData, cloudData);
      case 'assessments':
        return _mergeAssessmentData(localData, cloudData);
      case 'semesters':
        return _mergeSemesterData(localData, cloudData);
      case 'inventory_items':
        return _mergeInventoryData(localData, cloudData);
      case 'data_records':
        return _mergeDataRecordData(localData, cloudData);
      default:
        // Default merge: cloud data wins for unknown types
        return cloudData;
    }
  }

  /// Merge student data with conflict resolution
  static Map<String, dynamic> _mergeStudentData(
    Map<String, dynamic> local,
    Map<String, dynamic> cloud,
  ) {
    final merged = Map<String, dynamic>.from(cloud);

    // Keep the most complete contact information
    if (local['phoneNumber'] != null && cloud['phoneNumber'] == null) {
      merged['phoneNumber'] = local['phoneNumber'];
    }
    if (local['email'] != null && cloud['email'] == null) {
      merged['email'] = local['email'];
    }
    if (local['address'] != null && cloud['address'] == null) {
      merged['address'] = local['address'];
    }

    // Keep emergency contact if missing in cloud
    if (local['emergencyContactName'] != null && cloud['emergencyContactName'] == null) {
      merged['emergencyContactName'] = local['emergencyContactName'];
      merged['emergencyContactPhone'] = local['emergencyContactPhone'];
    }

    // Keep medical info if missing in cloud
    if (local['bloodType'] != null && cloud['bloodType'] == null) {
      merged['bloodType'] = local['bloodType'];
    }
    if (local['medicalConditions'] != null && cloud['medicalConditions'] == null) {
      merged['medicalConditions'] = local['medicalConditions'];
    }

    return merged;
  }

  /// Merge teacher data with conflict resolution
  static Map<String, dynamic> _mergeTeacherData(
    Map<String, dynamic> local,
    Map<String, dynamic> cloud,
  ) {
    final merged = Map<String, dynamic>.from(cloud);

    // Keep additional contact info if missing in cloud
    if (local['phoneNumber'] != null && cloud['phoneNumber'] == null) {
      merged['phoneNumber'] = local['phoneNumber'];
    }
    if (local['email'] != null && cloud['email'] == null) {
      merged['email'] = local['email'];
    }
    if (local['specialization'] != null && cloud['specialization'] == null) {
      merged['specialization'] = local['specialization'];
    }

    return merged;
  }

  /// Merge subject data with conflict resolution
  static Map<String, dynamic> _mergeSubjectData(
    Map<String, dynamic> local,
    Map<String, dynamic> cloud,
  ) {
    final merged = Map<String, dynamic>.from(cloud);

    // Keep description if missing in cloud
    if (local['description'] != null && cloud['description'] == null) {
      merged['description'] = local['description'];
    }

    return merged;
  }

  /// Merge class data with conflict resolution
  static Map<String, dynamic> _mergeClassData(
    Map<String, dynamic> local,
    Map<String, dynamic> cloud,
  ) {
    final merged = Map<String, dynamic>.from(cloud);

    // Keep additional info if missing in cloud
    if (local['description'] != null && cloud['description'] == null) {
      merged['description'] = local['description'];
    }
    if (local['capacity'] != null && cloud['capacity'] == null) {
      merged['capacity'] = local['capacity'];
    }

    return merged;
  }

  /// Merge timetable data with conflict resolution
  static Map<String, dynamic> _mergeTimetableData(
    Map<String, dynamic> local,
    Map<String, dynamic> cloud,
  ) {
    // For timetable entries, last modified wins
    final localTime = DateTime.tryParse(local['lastUpdated'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    final cloudTime = DateTime.tryParse(cloud['lastUpdated'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

    return localTime.isAfter(cloudTime) ? local : cloud;
  }

  /// Merge attendance data with conflict resolution
  static Map<String, dynamic> _mergeAttendanceData(
    Map<String, dynamic> local,
    Map<String, dynamic> cloud,
  ) {
    // For attendance, last modified wins
    final localTime = DateTime.tryParse(local['lastUpdated'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    final cloudTime = DateTime.tryParse(cloud['lastUpdated'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

    return localTime.isAfter(cloudTime) ? local : cloud;
  }

  /// Merge score data with conflict resolution
  static Map<String, dynamic> _mergeScoreData(
    Map<String, dynamic> local,
    Map<String, dynamic> cloud,
  ) {
    // For scores, last modified wins
    final localTime = DateTime.tryParse(local['lastUpdated'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    final cloudTime = DateTime.tryParse(cloud['lastUpdated'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

    return localTime.isAfter(cloudTime) ? local : cloud;
  }

  /// Merge assessment data with conflict resolution
  static Map<String, dynamic> _mergeAssessmentData(
    Map<String, dynamic> local,
    Map<String, dynamic> cloud,
  ) {
    final merged = Map<String, dynamic>.from(cloud);

    // Keep description if missing in cloud
    if (local['description'] != null && cloud['description'] == null) {
      merged['description'] = local['description'];
    }

    return merged;
  }

  /// Merge semester data with conflict resolution
  static Map<String, dynamic> _mergeSemesterData(
    Map<String, dynamic> local,
    Map<String, dynamic> cloud,
  ) {
    final merged = Map<String, dynamic>.from(cloud);

    // Keep description if missing in cloud
    if (local['description'] != null && cloud['description'] == null) {
      merged['description'] = local['description'];
    }

    return merged;
  }

  /// Merge inventory data with conflict resolution
  static Map<String, dynamic> _mergeInventoryData(
    Map<String, dynamic> local,
    Map<String, dynamic> cloud,
  ) {
    final merged = Map<String, dynamic>.from(cloud);

    // Keep description if missing in cloud
    if (local['description'] != null && cloud['description'] == null) {
      merged['description'] = local['description'];
    }

    return merged;
  }

  /// Merge data record data with conflict resolution
  static Map<String, dynamic> _mergeDataRecordData(
    Map<String, dynamic> local,
    Map<String, dynamic> cloud,
  ) {
    final merged = Map<String, dynamic>.from(cloud);

    // Keep content if missing in cloud
    if (local['content'] != null && cloud['content'] == null) {
      merged['content'] = local['content'];
    }

    // Keep attachment path if missing in cloud
    if (local['attachmentPath'] != null && cloud['attachmentPath'] == null) {
      merged['attachmentPath'] = local['attachmentPath'];
    }

    return merged;
  }

  /// Get recommended conflict strategy for a data type
  static ConflictStrategy getRecommendedStrategy(String collectionName) {
    switch (collectionName) {
      case 'attendance_records':
      case 'scores':
      case 'timetable_entries':
        // For time-sensitive data, use last modified wins
        return ConflictStrategy.localWins;
      case 'students':
      case 'teachers':
      case 'subjects':
      case 'class_sections':
        // For master data, prefer merge strategy
        return ConflictStrategy.merge;
      case 'assessments':
      case 'semesters':
      case 'inventory_items':
      case 'data_records':
        // For configuration data, prefer merge
        return ConflictStrategy.merge;
      default:
        return ConflictStrategy.cloudWins;
    }
  }

  /// Check if two data items have conflicts
  static bool hasConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> cloudData,
  ) {
    // Check if both have been modified since last sync
    final localLastUpdated = DateTime.tryParse(localData['lastUpdated'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
    final cloudLastUpdated = DateTime.tryParse(cloudData['lastUpdated'] ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

    // If timestamps are different, there's a potential conflict
    return localLastUpdated != cloudLastUpdated;
  }
}