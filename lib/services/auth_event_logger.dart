import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Comprehensive authentication event logging service
class AuthEventLogger {
  static const String _eventLogBoxName = 'auth_event_logs';
  static const String _eventQueueBoxName = 'auth_event_queue';
  static const int _maxStoredEvents = 1000;
  static const int _maxQueuedEvents = 100;
  static const Duration _syncInterval = Duration(minutes: 5);

  static bool _isInitialized = false;
  static Timer? _syncTimer;
  static StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  static final StreamController<AuthEvent> _eventStreamController = StreamController<AuthEvent>.broadcast();

  /// Initialize the event logger
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Hive.openBox(_eventLogBoxName);
      await Hive.openBox(_eventQueueBoxName);

      // Setup connectivity monitoring for sync
      _setupConnectivityMonitoring();

      // Start periodic sync
      _startPeriodicSync();

      _isInitialized = true;
      print('[AUTH_LOGGER] Authentication event logger initialized');

      // Log initialization event
      await logEvent(AuthEventType.serviceInitialized, 'Authentication event logger initialized successfully');

    } catch (e) {
      print('[AUTH_LOGGER] Failed to initialize event logger: $e');
      rethrow;
    }
  }

  /// Setup connectivity monitoring
  static void _setupConnectivityMonitoring() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        // Online - sync queued events
        _syncQueuedEvents();
      }
    });
  }

  /// Start periodic sync timer
  static void _startPeriodicSync() {
    _syncTimer = Timer.periodic(_syncInterval, (timer) {
      _syncQueuedEvents();
    });
  }

  /// Log an authentication event
  static Future<void> logEvent(
    AuthEventType type,
    String message, {
    String? userId,
    String? deviceId,
    Map<String, dynamic>? metadata,
    AuthEventSeverity severity = AuthEventSeverity.info,
  }) async {
    try {
      final event = AuthEvent(
        id: _generateEventId(),
        type: type,
        message: message,
        timestamp: DateTime.now(),
        userId: userId,
        deviceId: deviceId ?? await _getDeviceId(),
        severity: severity,
        metadata: metadata,
      );

      // Add to stream for real-time listeners
      if (!_eventStreamController.isClosed) {
        _eventStreamController.add(event);
      }

      // Store locally
      await _storeEventLocally(event);

      // Queue for sync if online
      if (await _isOnline()) {
        await _queueEventForSync(event);
      }

      // Log to console in debug mode
      if (_shouldLogToConsole(severity)) {
        print('[AUTH_EVENT] ${severity.toString().toUpperCase()}: $message');
      }

    } catch (e) {
      print('[AUTH_LOGGER] Failed to log event: $e');
    }
  }

  /// Log login attempt
  static Future<void> logLoginAttempt(String email, {String? deviceId, Map<String, dynamic>? metadata}) async {
    await logEvent(
      AuthEventType.loginAttempt,
      'Login attempt for: $email',
      userId: null, // User not yet authenticated
      deviceId: deviceId,
      metadata: {'email': email, ...?metadata},
    );
  }

  /// Log successful login
  static Future<void> logLoginSuccess(String userId, String email, {String? deviceId, Map<String, dynamic>? metadata}) async {
    await logEvent(
      AuthEventType.loginSuccessful,
      'Login successful for: $email',
      userId: userId,
      deviceId: deviceId,
      metadata: {'email': email, ...?metadata},
    );
  }

  /// Log failed login
  static Future<void> logLoginFailure(String email, String reason, {String? deviceId, Map<String, dynamic>? metadata}) async {
    await logEvent(
      AuthEventType.loginFailed,
      'Login failed for $email: $reason',
      userId: null,
      deviceId: deviceId,
      severity: AuthEventSeverity.warning,
      metadata: {'email': email, 'reason': reason, ...?metadata},
    );
  }

  /// Log logout
  static Future<void> logLogout(String userId, {String? deviceId, Map<String, dynamic>? metadata}) async {
    await logEvent(
      AuthEventType.logoutSuccessful,
      'User logged out',
      userId: userId,
      deviceId: deviceId,
      metadata: metadata,
    );
  }

  /// Log biometric authentication
  static Future<void> logBiometricAuth(String userId, bool success, {String? deviceId, Map<String, dynamic>? metadata}) async {
    final eventType = success ? AuthEventType.biometricAuthSuccessful : AuthEventType.biometricAuthFailed;
    final severity = success ? AuthEventSeverity.info : AuthEventSeverity.warning;

    await logEvent(
      eventType,
      'Biometric authentication ${success ? 'successful' : 'failed'}',
      userId: userId,
      deviceId: deviceId,
      severity: severity,
      metadata: metadata,
    );
  }

  /// Log session events
  static Future<void> logSessionEvent(AuthEventType type, String userId, {String? deviceId, Map<String, dynamic>? metadata}) async {
    String message;
    switch (type) {
      case AuthEventType.sessionExpired:
        message = 'User session expired';
        break;
      case AuthEventType.sessionRestored:
        message = 'User session restored';
        break;
      default:
        message = 'Session event';
    }

    await logEvent(type, message, userId: userId, deviceId: deviceId, metadata: metadata);
  }

  /// Log security events
  static Future<void> logSecurityEvent(String userId, String event, AuthEventSeverity severity, {String? deviceId, Map<String, dynamic>? metadata}) async {
    await logEvent(
      AuthEventType.securityEvent,
      event,
      userId: userId,
      deviceId: deviceId,
      severity: severity,
      metadata: metadata,
    );
  }

  /// Log MFA events
  static Future<void> logMFAEvent(String userId, AuthEventType type, {String? deviceId, Map<String, dynamic>? metadata}) async {
    String message;
    switch (type) {
      case AuthEventType.mfaRequired:
        message = 'Multi-factor authentication required';
        break;
      case AuthEventType.mfaVerified:
        message = 'Multi-factor authentication verified';
        break;
      default:
        message = 'MFA event';
    }

    await logEvent(type, message, userId: userId, deviceId: deviceId, metadata: metadata);
  }

  /// Store event locally
  static Future<void> _storeEventLocally(AuthEvent event) async {
    try {
      final eventBox = await Hive.openBox(_eventLogBoxName);
      final events = eventBox.get('events', defaultValue: <Map<String, dynamic>>[]);

      if (events is List) {
        events.add(event.toJson());

        // Keep only the most recent events
        if (events.length > _maxStoredEvents) {
          events.removeRange(0, events.length - _maxStoredEvents);
        }

        await eventBox.put('events', events);
      }
    } catch (e) {
      print('[AUTH_LOGGER] Failed to store event locally: $e');
    }
  }

  /// Queue event for sync
  static Future<void> _queueEventForSync(AuthEvent event) async {
    try {
      final queueBox = await Hive.openBox(_eventQueueBoxName);
      final queuedEvents = queueBox.get('queued_events', defaultValue: <Map<String, dynamic>>[]);

      if (queuedEvents is List) {
        queuedEvents.add(event.toJson());

        // Keep only the most recent queued events
        if (queuedEvents.length > _maxQueuedEvents) {
          queuedEvents.removeRange(0, queuedEvents.length - _maxQueuedEvents);
        }

        await queueBox.put('queued_events', queuedEvents);
      }
    } catch (e) {
      print('[AUTH_LOGGER] Failed to queue event for sync: $e');
    }
  }

  /// Sync queued events
  static Future<void> _syncQueuedEvents() async {
    try {
      if (!await _isOnline()) return;

      final queueBox = await Hive.openBox(_eventQueueBoxName);
      final queuedEvents = queueBox.get('queued_events', defaultValue: <Map<String, dynamic>>[]);

      if (queuedEvents is List && queuedEvents.isNotEmpty) {
        // TODO: Implement actual sync to remote server
        // For now, just clear the queue
        await queueBox.put('queued_events', <Map<String, dynamic>>[]);
        print('[AUTH_LOGGER] Synced ${queuedEvents.length} events');
      }
    } catch (e) {
      print('[AUTH_LOGGER] Failed to sync queued events: $e');
    }
  }

  /// Get stored events
  static Future<List<AuthEvent>> getStoredEvents({
    int limit = 100,
    AuthEventType? type,
    String? userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final eventBox = await Hive.openBox(_eventLogBoxName);
      final eventsData = eventBox.get('events', defaultValue: <Map<String, dynamic>>[]);

      if (eventsData is! List) return [];

      List<AuthEvent> events = eventsData
          .map((data) => AuthEvent.fromJson(data))
          .where((event) {
            if (type != null && event.type != type) return false;
            if (userId != null && event.userId != userId) return false;
            if (startDate != null && event.timestamp.isBefore(startDate)) return false;
            if (endDate != null && event.timestamp.isAfter(endDate)) return false;
            return true;
          })
          .toList();

      // Sort by timestamp (newest first) and limit
      events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (events.length > limit) {
        events = events.sublist(0, limit);
      }

      return events;
    } catch (e) {
      print('[AUTH_LOGGER] Failed to get stored events: $e');
      return [];
    }
  }

  /// Get event statistics
  static Future<Map<String, dynamic>> getEventStatistics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final events = await getStoredEvents(
        limit: _maxStoredEvents,
        startDate: startDate,
        endDate: endDate,
      );

      final stats = {
        'totalEvents': events.length,
        'eventsByType': <String, int>{},
        'eventsBySeverity': <String, int>{},
        'eventsByUser': <String, int>{},
        'recentEvents': events.take(10).map((e) => e.toJson()).toList(),
      };

      for (final event in events) {
        // Count by type
        final typeKey = event.type.toString();
        final eventsByType = stats['eventsByType'] as Map<String, int>;
        eventsByType[typeKey] = (eventsByType[typeKey] ?? 0) + 1;

        // Count by severity
        final severityKey = event.severity.toString();
        final eventsBySeverity = stats['eventsBySeverity'] as Map<String, int>;
        eventsBySeverity[severityKey] = (eventsBySeverity[severityKey] ?? 0) + 1;

        // Count by user
        if (event.userId != null) {
          final eventsByUser = stats['eventsByUser'] as Map<String, int>;
          eventsByUser[event.userId!] = (eventsByUser[event.userId!] ?? 0) + 1;
        }
      }

      return stats;
    } catch (e) {
      print('[AUTH_LOGGER] Failed to get event statistics: $e');
      return {};
    }
  }

  /// Clear old events
  static Future<void> clearOldEvents({Duration maxAge = const Duration(days: 30)}) async {
    try {
      final eventBox = await Hive.openBox(_eventLogBoxName);
      final eventsData = eventBox.get('events', defaultValue: <Map<String, dynamic>>[]);

      if (eventsData is List) {
        final cutoffDate = DateTime.now().subtract(maxAge);
        final filteredEvents = eventsData.where((eventData) {
          try {
            final event = AuthEvent.fromJson(eventData);
            return event.timestamp.isAfter(cutoffDate);
          } catch (e) {
            return false;
          }
        }).toList();

        await eventBox.put('events', filteredEvents);
        print('[AUTH_LOGGER] Cleared ${eventsData.length - filteredEvents.length} old events');
      }
    } catch (e) {
      print('[AUTH_LOGGER] Failed to clear old events: $e');
    }
  }

  /// Generate unique event ID
  static String _generateEventId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = DateTime.now().microsecondsSinceEpoch.toString();
    return 'auth_event_${timestamp}_$random';
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
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  /// Check if event should be logged to console
  static bool _shouldLogToConsole(AuthEventSeverity severity) {
    // Log warnings and errors to console
    return severity == AuthEventSeverity.warning || severity == AuthEventSeverity.error;
  }

  /// Get event stream for real-time monitoring
  static Stream<AuthEvent> get eventStream => _eventStreamController.stream;

  /// Dispose resources
  static void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _eventStreamController.close();
    print('[AUTH_LOGGER] Authentication event logger disposed');
  }
}

/// Authentication event types
enum AuthEventType {
  serviceInitialized,
  loginAttempt,
  loginSuccessful,
  loginFailed,
  offlineLoginSuccessful,
  registrationAttempt,
  registrationSuccessful,
  registrationFailed,
  logoutSuccessful,
  sessionExpired,
  sessionRestored,
  biometricAuthAttempt,
  biometricAuthSuccessful,
  biometricAuthFailed,
  mfaRequired,
  mfaVerified,
  passwordResetRequested,
  passwordResetSuccessful,
  emailVerificationSent,
  emailVerified,
  securityEvent,
  connectivityChanged,
  error,
}

/// Authentication event severity levels
enum AuthEventSeverity {
  debug,
  info,
  warning,
  error,
  critical,
}

/// Authentication event model
class AuthEvent {
  final String id;
  final AuthEventType type;
  final String message;
  final DateTime timestamp;
  final String? userId;
  final String? deviceId;
  final AuthEventSeverity severity;
  final Map<String, dynamic>? metadata;

  AuthEvent({
    required this.id,
    required this.type,
    required this.message,
    required this.timestamp,
    this.userId,
    this.deviceId,
    this.severity = AuthEventSeverity.info,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'userId': userId,
      'deviceId': deviceId,
      'severity': severity.toString(),
      'metadata': metadata,
    };
  }

  factory AuthEvent.fromJson(Map<String, dynamic> json) {
    return AuthEvent(
      id: json['id'],
      type: _parseEventType(json['type']),
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      userId: json['userId'],
      deviceId: json['deviceId'],
      severity: _parseEventSeverity(json['severity']),
      metadata: json['metadata'],
    );
  }

  static AuthEventType _parseEventType(String typeString) {
    return AuthEventType.values.firstWhere(
      (type) => type.toString() == typeString,
      orElse: () => AuthEventType.error,
    );
  }

  static AuthEventSeverity _parseEventSeverity(String severityString) {
    return AuthEventSeverity.values.firstWhere(
      (severity) => severity.toString() == severityString,
      orElse: () => AuthEventSeverity.info,
    );
  }
}