// =============================================================
// FILE: lib/screens/timetable/timetable_screen.dart (UPDATED)
// =============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/l10n/app_localizations.dart';
import 'package:smart_school_assistant/models.dart';
import 'package:smart_school_assistant/services/timetable_service.dart';
import 'timetable_settings_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];

  Future<void> _editTimetableEntry(
      BuildContext context, String day, String periodId) async {
    final subjectsBox = Hive.box<Subject>('subjects');
    final timetableBox = Hive.box<TimeTableEntry>('timetable_entries');

    final subjects = subjectsBox.values.toList();
    if (subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.noSubjectsFound)),
      );
      return;
    }

    // Find existing entry
    TimeTableEntry? existingEntry;
    try {
      existingEntry = timetableBox.values.firstWhere(
        (e) => e.dayOfWeek == day && e.period == periodId,
      );
    } catch (e) {
      existingEntry = null;
    }

    String? selectedSubjectId = existingEntry?.subjectId;

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectSubject),
          content: DropdownButtonFormField<String>(
            value: selectedSubjectId,
            hint: Text(AppLocalizations.of(context)!.selectSubject),
            items: subjects.map((subject) {
              return DropdownMenuItem(
                value: subject.id,
                child: Text(subject.name),
              );
            }).toList(),
            onChanged: (value) {
              selectedSubjectId = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(selectedSubjectId),
              child: Text(AppLocalizations.of(context)!.save),
            ),
          ],
        );
      },
    );

    if (result != null) {
      if (result.isEmpty) {
        // Remove entry if no subject selected
        if (existingEntry != null) {
          await existingEntry.delete();
        }
      } else {
        // Update or create entry
        if (existingEntry != null) {
          existingEntry.subjectId = result;
          await existingEntry.save();
        } else {
          final newEntry = TimeTableEntry(
            dayOfWeek: day,
            period: periodId,
            subjectId: result,
            classSectionId: '', // Assuming single timetable
          );
          await timetableBox.add(newEntry);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.weeklyTimetable),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const TimetableSettingsScreen()),
              );
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating new timetable...')),
              );
              await TimetableService.generateTimetable();
              if (mounted) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('New timetable generated!'),
                      backgroundColor: Colors.green),
                );
              }
            },
            tooltip: 'Generate Timetable',
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<Period>>(
        valueListenable: Hive.box<Period>('periods').listenable(),
        builder: (context, periodsBox, _) {
          final periods = periodsBox.values.toList();
          if (periods.isEmpty) {
            return const Center(
              child:
                  Text('No periods defined. Please add periods in settings.'),
            );
          }
          return ValueListenableBuilder<Box<TimeTableEntry>>(
            valueListenable:
                Hive.box<TimeTableEntry>('timetable_entries').listenable(),
            builder: (context, timetableBox, __) {
              final subjectsBox = Hive.box<Subject>('subjects');

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    columnSpacing: 20,
                    border: TableBorder.all(color: Colors.grey.shade300),
                    columns: [
                      const DataColumn(
                          label: Text('Time',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      ...days.map((day) => DataColumn(
                          label: Text(day,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)))),
                    ],
                    rows: List<DataRow>.generate(
                      periods.length,
                      (periodIndex) {
                        final period = periods[periodIndex];
                        return DataRow(
                          cells: [
                            DataCell(Text('${period.name}\n${period.time}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                            ...List<DataCell>.generate(
                              days.length,
                              (dayIndex) {
                                final day = days[dayIndex];
                                final entry = timetableBox.values.firstWhere(
                                  (e) =>
                                      e.dayOfWeek == day &&
                                      e.period == period.id,
                                  orElse: () => TimeTableEntry(
                                      dayOfWeek: '',
                                      period: '',
                                      subjectId: '',
                                      classSectionId: ''),
                                );

                                String subjectName = '-';
                                if (entry.subjectId.isNotEmpty) {
                                  final subject = subjectsBox.values.firstWhere(
                                    (s) => s.id == entry.subjectId,
                                    orElse: () => Subject(
                                        id: '', name: 'Unknown', teacherId: ''),
                                  );
                                  subjectName = subject.name;
                                }

                                return DataCell(
                                  InkWell(
                                    onTap: () => _editTimetableEntry(
                                        context, day, period.id),
                                    child: Container(
                                      color: period.isBreak
                                          ? Colors.amber.shade100
                                          : Colors.transparent,
                                      width: 120,
                                      child: Center(
                                        child: Text(
                                          period.isBreak
                                              ? AppLocalizations.of(context)!
                                                  .breakPeriod
                                              : subjectName,
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
