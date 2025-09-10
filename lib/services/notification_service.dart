import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'dart:io' show Platform;
import 'package:permission_handler/permission_handler.dart';

/// Notification types for different events
enum NotificationType {
  syncSuccess,
  syncFailure,
  syncConflict,
  backgroundSync,
  systemAlert,
  userAction,
  dataUpdate,
}

/// Notification priority levels
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Notification service for handling local notifications
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;

  /// Initialize the notification service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    // Initialize timezone data
    tz.initializeTimeZones();

    // Android initialization settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Combined initialization settings
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Initialize the plugin
    await _notificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }

    // Request permissions
    await _requestPermissions();

    _isInitialized = true;
  }

  /// Create notification channels for Android
  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel syncChannel = AndroidNotificationChannel(
      'sync_channel',
      'Sync Notifications',
      description: 'Notifications for sync operations',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel alertChannel = AndroidNotificationChannel(
      'alert_channel',
      'System Alerts',
      description: 'Important system alerts and warnings',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel dataChannel = AndroidNotificationChannel(
      'data_channel',
      'Data Updates',
      description: 'Notifications for data changes and updates',
      importance: Importance.low,
      playSound: false,
      enableVibration: false,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(syncChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(dataChannel);
  }

  /// Request notification permissions
  static Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _notificationsPlugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final status = await Permission.notification.request();
      if (status.isDenied) {
        // Handle permission denied
        // TODO: Handle notification permission denied
      }
    }
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap based on payload
    final payload = response.payload;
    if (payload != null) {
      // Navigate to appropriate screen based on payload
      // TODO: Handle notification tap with payload: $payload
    }
  }

  /// Show a notification
  static Future<void> showNotification({
    required String title,
    required String body,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    String? payload,
    bool enableSound = true,
    bool enableVibration = true,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _getChannelId(type),
      _getChannelName(type),
      channelDescription: _getChannelDescription(type),
      importance: _getImportance(priority),
      priority: _getAndroidPriority(priority),
      playSound: enableSound,
      enableVibration: enableVibration,
      icon: '@mipmap/ic_launcher',
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedule a notification for later
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required NotificationType type,
    NotificationPriority priority = NotificationPriority.normal,
    String? payload,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    final id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _getChannelId(type),
      _getChannelName(type),
      channelDescription: _getChannelDescription(type),
      importance: _getImportance(priority),
      priority: _getAndroidPriority(priority),
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  /// Cancel a specific notification
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  /// Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notificationsPlugin.pendingNotificationRequests();
  }

  /// Helper methods for notification configuration
  static String _getChannelId(NotificationType type) {
    switch (type) {
      case NotificationType.syncSuccess:
      case NotificationType.syncFailure:
      case NotificationType.syncConflict:
      case NotificationType.backgroundSync:
        return 'sync_channel';
      case NotificationType.systemAlert:
        return 'alert_channel';
      case NotificationType.userAction:
      case NotificationType.dataUpdate:
        return 'data_channel';
    }
  }

  static String _getChannelName(NotificationType type) {
    switch (type) {
      case NotificationType.syncSuccess:
      case NotificationType.syncFailure:
      case NotificationType.syncConflict:
      case NotificationType.backgroundSync:
        return 'Sync Notifications';
      case NotificationType.systemAlert:
        return 'System Alerts';
      case NotificationType.userAction:
      case NotificationType.dataUpdate:
        return 'Data Updates';
    }
  }

  static String _getChannelDescription(NotificationType type) {
    switch (type) {
      case NotificationType.syncSuccess:
      case NotificationType.syncFailure:
      case NotificationType.syncConflict:
      case NotificationType.backgroundSync:
        return 'Notifications for sync operations';
      case NotificationType.systemAlert:
        return 'Important system alerts and warnings';
      case NotificationType.userAction:
      case NotificationType.dataUpdate:
        return 'Notifications for data changes and updates';
    }
  }

  static Importance _getImportance(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Importance.low;
      case NotificationPriority.normal:
        return Importance.defaultImportance;
      case NotificationPriority.high:
        return Importance.high;
      case NotificationPriority.urgent:
        return Importance.max;
    }
  }

  static Priority _getAndroidPriority(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Priority.low;
      case NotificationPriority.normal:
        return Priority.defaultPriority;
      case NotificationPriority.high:
        return Priority.high;
      case NotificationPriority.urgent:
        return Priority.max;
    }
  }

  /// Convenience methods for common notifications

  /// Show sync success notification
  static Future<void> showSyncSuccessNotification({
    required String message,
    String? details,
  }) async {
    final body = details != null ? '$message\n$details' : message;
    await showNotification(
      title: 'Sync Completed',
      body: body,
      type: NotificationType.syncSuccess,
      priority: NotificationPriority.normal,
      payload: 'sync_success',
    );
  }

  /// Show sync failure notification
  static Future<void> showSyncFailureNotification({
    required String error,
    String? details,
  }) async {
    final body = details != null ? '$error\n$details' : error;
    await showNotification(
      title: 'Sync Failed',
      body: body,
      type: NotificationType.syncFailure,
      priority: NotificationPriority.high,
      payload: 'sync_failure',
    );
  }

  /// Show sync conflict notification
  static Future<void> showSyncConflictNotification({
    required int conflictCount,
  }) async {
    await showNotification(
      title: 'Sync Conflicts Detected',
      body: '$conflictCount conflicts need to be resolved',
      type: NotificationType.syncConflict,
      priority: NotificationPriority.urgent,
      payload: 'sync_conflict',
    );
  }

  /// Show background sync notification
  static Future<void> showBackgroundSyncNotification({
    required String status,
  }) async {
    await showNotification(
      title: 'Background Sync',
      body: status,
      type: NotificationType.backgroundSync,
      priority: NotificationPriority.low,
      enableSound: false,
      enableVibration: false,
      payload: 'background_sync',
    );
  }

  /// Show system alert notification
  static Future<void> showSystemAlertNotification({
    required String title,
    required String message,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    await showNotification(
      title: title,
      body: message,
      type: NotificationType.systemAlert,
      priority: priority,
      payload: 'system_alert',
    );
  }

  /// Show data update notification
  static Future<void> showDataUpdateNotification({
    required String entityType,
    required String action,
    String? details,
  }) async {
    final body = details != null ? '$action\n$details' : action;
    await showNotification(
      title: '$entityType Updated',
      body: body,
      type: NotificationType.dataUpdate,
      priority: NotificationPriority.low,
      enableSound: false,
      enableVibration: false,
      payload: 'data_update',
    );
  }

  /// Show user action notification
  static Future<void> showUserActionNotification({
    required String action,
    required String details,
  }) async {
    await showNotification(
      title: 'Action Completed',
      body: '$action: $details',
      type: NotificationType.userAction,
      priority: NotificationPriority.normal,
      payload: 'user_action',
    );
  }
}

/// Analytics service for tracking app usage and performance
class AnalyticsService {
  static final List<Map<String, dynamic>> _events = [];
  static bool _isEnabled = true;

  /// Enable or disable analytics
  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Track a user action
  static void trackAction({
    required String action,
    required String screen,
    Map<String, dynamic>? parameters,
    String? userId,
  }) {
    if (!_isEnabled) return;

    final event = {
      'type': 'action',
      'action': action,
      'screen': screen,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
      'parameters': parameters ?? {},
    };

    _events.add(event);
    _logEvent(event);
  }

  /// Track a screen view
  static void trackScreenView({
    required String screenName,
    String? previousScreen,
    String? userId,
  }) {
    if (!_isEnabled) return;

    final event = {
      'type': 'screen_view',
      'screen': screenName,
      'previousScreen': previousScreen,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
    };

    _events.add(event);
    _logEvent(event);
  }

  /// Track an error
  static void trackError({
    required String error,
    required String screen,
    String? stackTrace,
    String? userId,
  }) {
    if (!_isEnabled) return;

    final event = {
      'type': 'error',
      'error': error,
      'screen': screen,
      'stackTrace': stackTrace,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
    };

    _events.add(event);
    _logEvent(event);
  }

  /// Track sync operation
  static void trackSync({
    required String operation,
    required bool success,
    int? durationMs,
    int? recordsProcessed,
    String? error,
    String? userId,
  }) {
    if (!_isEnabled) return;

    final event = {
      'type': 'sync',
      'operation': operation,
      'success': success,
      'durationMs': durationMs,
      'recordsProcessed': recordsProcessed,
      'error': error,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
    };

    _events.add(event);
    _logEvent(event);

    // Send notification for sync events
    if (success) {
      NotificationService.showSyncSuccessNotification(
        message: '$operation completed successfully',
        details: recordsProcessed != null ? '$recordsProcessed records processed' : null,
      );
    } else {
      NotificationService.showSyncFailureNotification(
        error: '$operation failed',
        details: error,
      );
    }
  }

  /// Track performance metric
  static void trackPerformance({
    required String metric,
    required int value,
    String? unit,
    String? screen,
    String? userId,
  }) {
    if (!_isEnabled) return;

    final event = {
      'type': 'performance',
      'metric': metric,
      'value': value,
      'unit': unit,
      'screen': screen,
      'timestamp': DateTime.now().toIso8601String(),
      'userId': userId,
    };

    _events.add(event);
    _logEvent(event);
  }

  /// Get analytics summary
  static Map<String, dynamic> getAnalyticsSummary() {
    final summary = {
      'totalEvents': _events.length,
      'eventsByType': <String, int>{},
      'eventsByScreen': <String, int>{},
      'syncSuccessRate': 0.0,
      'averageSyncDuration': 0,
      'errorCount': 0,
    };

    int syncCount = 0;
    int syncSuccessCount = 0;
    int totalSyncDuration = 0;
    int errorCount = 0;

    for (final event in _events) {
      final type = event['type'] as String;
      final eventsByType = summary['eventsByType'] as Map<String, int>;
      eventsByType[type] = (eventsByType[type] ?? 0) + 1;

      if (event.containsKey('screen') && event['screen'] != null) {
        final screen = event['screen'] as String;
        final eventsByScreen = summary['eventsByScreen'] as Map<String, int>;
        eventsByScreen[screen] = (eventsByScreen[screen] ?? 0) + 1;
      }

      if (type == 'sync') {
        syncCount++;
        if (event['success'] == true) {
          syncSuccessCount++;
        }
        if (event['durationMs'] != null) {
          totalSyncDuration += event['durationMs'] as int;
        }
      }

      if (type == 'error') {
        errorCount++;
      }
    }

    if (syncCount > 0) {
      summary['syncSuccessRate'] = syncSuccessCount / syncCount;
      summary['averageSyncDuration'] = totalSyncDuration ~/ syncCount;
    }
    summary['errorCount'] = errorCount;

    return summary;
  }

  /// Clear all analytics data
  static void clearAnalytics() {
    _events.clear();
  }

  /// Export analytics data
  static List<Map<String, dynamic>> exportAnalytics() {
    return List.from(_events);
  }

  /// Log event to console (for debugging)
  static void _logEvent(Map<String, dynamic> event) {
    // Analytics Event: ${event['type']} - ${event['action'] ?? event['screen'] ?? event['error'] ?? event['metric'] ?? 'Unknown'}
  }
}