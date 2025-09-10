import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

import 'models.dart' as models;
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/firebase_service.dart';
import 'services/local_auth_service.dart';
import 'services/menu_visibility_service.dart';
import 'services/session_manager.dart';
import 'services/sync_service.dart';
import 'services/encryption_service.dart';

final GlobalKey<SmartSchoolAppState> appKey = GlobalKey();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await FirebaseService.initializeFirebase();
    developer.log('Firebase initialized successfully', name: 'SmartSchoolApp');
  } catch (e) {
    developer.log('Failed to initialize Firebase: $e', name: 'SmartSchoolApp', error: e);
    // Continue without Firebase for offline functionality
  }

  final Directory appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  // Initialize other services
  await MenuVisibilityService.initialize();
  await SessionManager.initialize();
  await SyncService.initialize();
  await EncryptionService.initialize();

  // Initialize local authentication service
  await LocalAuthService.initialize();

  // Register adapters
  Hive.registerAdapter(models.StudentAdapter());
  Hive.registerAdapter(models.TeacherAdapter());
  Hive.registerAdapter(models.SubjectAdapter());
  Hive.registerAdapter(models.ClassSectionAdapter());
  Hive.registerAdapter(models.ScoreAdapter());
  Hive.registerAdapter(models.AttendanceRecordAdapter());
  Hive.registerAdapter(models.TimeTableEntryAdapter());
  Hive.registerAdapter(models.PeriodAdapter());
  Hive.registerAdapter(models.InventoryItemAdapter());
  Hive.registerAdapter(models.DataRecordAdapter());
  Hive.registerAdapter(models.AssessmentAdapter());
  Hive.registerAdapter(models.SemesterAdapter());
  Hive.registerAdapter(models.AssessmentScoreAdapter());
  Hive.registerAdapter(models.UserAdapter());

  // Open all Hive boxes
  await Hive.openBox<models.Student>('students');
  await Hive.openBox<models.Teacher>('teachers');
  await Hive.openBox<models.Subject>('subjects');
  await Hive.openBox<models.ClassSection>('class_sections');
  await Hive.openBox<models.AttendanceRecord>('attendance_records');
  await Hive.openBox<models.Score>('scores');
  await Hive.openBox<models.Period>('periods');
  await Hive.openBox<models.TimeTableEntry>('timetable_entries');
  await Hive.openBox<models.InventoryItem>('inventory_items');
  await Hive.openBox<models.DataRecord>('data_records');
  await Hive.openBox<models.Assessment>('assessments');
  await Hive.openBox<models.Semester>('semesters');
  await Hive.openBox<models.AssessmentScore>('assessment_scores');
  await Hive.openBox<models.User>('users');
  await Hive.openBox('preferences'); // Open preferences box for admin setup flag

  // Open additional service boxes
  await Hive.openBox('local_auth'); // For LocalAuthService
  await Hive.openBox('user_sessions'); // For SessionManager and FirebaseService
  await Hive.openBox('menu_settings'); // For MenuVisibilityService
  await Hive.openBox('mfa'); // For MFAService
  await Hive.openBox('sync_status'); // For SyncService
  await Hive.openBox('social_auth'); // For SocialAuthService
  await Hive.openBox('auth_session'); // For FirebaseService session management
  await Hive.openBox('user_sync'); // For UserSyncService
  await Hive.openBox('encryption_keys'); // For EncryptionService
  await Hive.openBox('biometric'); // For BiometricService
  await Hive.openBox('auth_state'); // For AuthMiddleware
  await Hive.openBox('auth_events'); // For AuthEventLogger
  await Hive.openBox('auth_event_queue'); // For AuthEventLogger
  await Hive.openBox('admin_users'); // For AdminUserService
  await Hive.openBox('admin_settings'); // For AdminUserService
  await Hive.openBox('admin_audit'); // For AdminUserService
  await Hive.openBox('auth_test_results'); // For AuthTestSuite

  runApp(SmartSchoolApp(key: appKey));
}

class SmartSchoolApp extends StatefulWidget {
  const SmartSchoolApp({super.key});

  @override
  State<SmartSchoolApp> createState() => SmartSchoolAppState();
}

class SmartSchoolAppState extends State<SmartSchoolApp> {
  Locale _locale = const Locale('en');
  bool _isDarkMode = false;
  bool _isLoading = true;
  bool _adminSetupComplete = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _loadSettings();
    await _checkAdminSetup();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    final darkMode = prefs.getBool('darkMode') ?? false;
    setState(() {
      _locale = Locale(languageCode);
      _isDarkMode = darkMode;
    });
  }

  Future<void> _checkAdminSetup() async {
    try {
      final prefs = await Hive.openBox('preferences');
      final adminSetupComplete = prefs.get('adminSetupComplete', defaultValue: false);
      setState(() {
        _adminSetupComplete = adminSetupComplete;
      });
    } catch (e) {
      setState(() {
        _adminSetupComplete = false;
      });
    }
  }

  // Method to refresh admin setup status (called after admin setup completion)
  void refreshAdminSetupStatus() {
    _checkAdminSetup();
  }

  void setLocale(Locale newLocale) {
    _locale = newLocale;
    setState(() {});
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('languageCode', newLocale.languageCode);
    });
  }

  void setDarkMode(bool isDark) {
    _isDarkMode = isDark;
    setState(() {});
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('darkMode', isDark);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Always show login screen first - it will handle admin setup check internally
    Widget homeScreen;
    if (FirebaseService.isAuthenticated && _adminSetupComplete) {
      // User is authenticated and admin setup is complete, show home screen
      homeScreen = const HomeScreen();
    } else {
      // Show unified login screen that handles all authentication scenarios
      homeScreen = const LoginScreen();
    }

    return MaterialApp(
      key: ValueKey('$_locale.languageCode_$_isDarkMode'),
      title: 'Smart School Assistant',
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: _locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: homeScreen,
    );
  }
}