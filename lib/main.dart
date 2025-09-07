import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'theme/app_theme.dart';

import 'models.dart';
import 'screens/home_screen.dart';

final GlobalKey<SmartSchoolAppState> appKey = GlobalKey();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final Directory appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);
  Hive.registerAdapter(StudentAdapter());
  Hive.registerAdapter(TeacherAdapter());
  Hive.registerAdapter(SubjectAdapter());
  Hive.registerAdapter(ClassSectionAdapter());
  Hive.registerAdapter(ScoreAdapter());
  Hive.registerAdapter(AttendanceRecordAdapter());
  Hive.registerAdapter(TimeTableEntryAdapter());
  Hive.registerAdapter(PeriodAdapter());
  Hive.registerAdapter(InventoryItemAdapter());
  Hive.registerAdapter(DataRecordAdapter());
  Hive.registerAdapter(AssessmentAdapter());
  Hive.registerAdapter(SemesterAdapter());
  Hive.registerAdapter(AssessmentScoreAdapter());

  // Open all Hive boxes
  await Hive.openBox<Student>('students');
  await Hive.openBox<Teacher>('teachers');
  await Hive.openBox<Subject>('subjects');
  await Hive.openBox<ClassSection>('class_sections');
  await Hive.openBox<AttendanceRecord>('attendance_records');
  await Hive.openBox<Score>('scores');
  await Hive.openBox<Period>('periods');
  await Hive.openBox<TimeTableEntry>('timetable_entries');
  await Hive.openBox<InventoryItem>('inventory_items');
  await Hive.openBox<DataRecord>('data_records');
  await Hive.openBox<Assessment>('assessments');
  await Hive.openBox<Semester>('semesters');
  await Hive.openBox<AssessmentScore>('assessment_scores');

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

  @override
  void initState() {
    super.initState();
    _loadSettings();
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
    return MaterialApp(
      key: ValueKey('${_locale.languageCode}_${_isDarkMode}'),
      title: 'Smart School Assistant',
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      locale: _locale,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }
}