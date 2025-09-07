// =============================================================
// FILE: lib/services/timetable_service.dart (NEW FILE)
// =============================================================
import 'package:hive/hive.dart';
import 'package:smart_school_assistant/models.dart';
import 'dart:math';

class TimetableService {
  static Future<void> generateTimetable() async {
    final subjectsBox = Hive.box<Subject>('subjects');
    final periodsBox = Hive.box<Period>('periods');
    final timetableBox = Hive.box<TimeTableEntry>('timetable_entries');

    final allSubjects = subjectsBox.values.toList();
    final allPeriods = periodsBox.values.where((p) => !p.isBreak).toList();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

    if (allSubjects.isEmpty || allPeriods.isEmpty) {
      // Not enough data to generate a schedule
      return;
    }

    // Clear the old timetable before generating a new one
    await timetableBox.clear();

    // Data structures to track constraints
    var teacherSchedule = <String, List<int>>{}; // teacherId -> [period indices]
    var classSchedule = <String, List<int>>{}; // day -> [period indices]

    // Initialize schedules
    for (var day in days) {
      classSchedule[day] = [];
    }

    final random = Random();
    // Shuffle subjects to get a different timetable each time
    final shuffledSubjects = List<Subject>.from(allSubjects)..shuffle(random);

    for (var subject in shuffledSubjects) {
      bool placed = false;
      // Try to place each subject in a random, valid slot
      for (int i = 0; i < 50 && !placed; i++) { // Limit attempts to prevent infinite loops
        final randomDay = days[random.nextInt(days.length)];
        final randomPeriodIndex = random.nextInt(allPeriods.length);
        final period = allPeriods[randomPeriodIndex];

        // Check constraints
        final isTeacherFree = !(teacherSchedule[subject.teacherId]?.contains(randomPeriodIndex) ?? false);
        final isClassSlotFree = !(classSchedule[randomDay]?.contains(randomPeriodIndex) ?? false);

        if (isTeacherFree && isClassSlotFree) {
          // Place the subject
          final entry = TimeTableEntry(
            dayOfWeek: randomDay,
            period: period.id, // Use period ID to link
            subjectId: subject.id,
            classSectionId: '', // Assuming one timetable for the whole school for now
          );
          timetableBox.add(entry);

          // Update constraints
          (teacherSchedule[subject.teacherId] ??= []).add(randomPeriodIndex);
          (classSchedule[randomDay] ??= []).add(randomPeriodIndex);

          placed = true;
        }
      }
    }
  }
}
