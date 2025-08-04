// FILE: lib/main.dart (UPDATED & FIXED)
// =============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// Import your data models and the new home screen
import 'models.dart';
import 'screens/home_screen.dart'; // <-- NEW IMPORT

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- HIVE DATABASE INITIALIZATION ---
  final Directory appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  Hive.registerAdapter(StudentAdapter());
  Hive.registerAdapter(TeacherAdapter());
  Hive.registerAdapter(SubjectAdapter());
  Hive.registerAdapter(ClassSectionAdapter());
  Hive.registerAdapter(ScoreAdapter());
  Hive.registerAdapter(AttendanceRecordAdapter());
  Hive.registerAdapter(TimeTableEntryAdapter());

  await Hive.openBox<ClassSection>('class_sections');
  await Hive.openBox<Student>('students');
  await Hive.openBox<Teacher>('teachers');
  await Hive.openBox<Subject>('subjects');
// In main.dart, inside the main() function
  await Hive.openBox<AttendanceRecord>('attendance_records');
  await Hive.openBox<Score>('scores'); // <-- ADD THIS LINE
  runApp(const SmartSchoolApp());
}

class SmartSchoolApp extends StatelessWidget {
  const SmartSchoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart School Assistant',
      theme: ThemeData(
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            elevation: 2,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Colors.amber,
          ),
          // --- FIX IS HERE ---
          cardTheme: CardThemeData( // Removed 'const' from here
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          )
      ),
      // The HomeScreen is now the entry point of the UI
      home: const HomeScreen(),
    );
  }
}