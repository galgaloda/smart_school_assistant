// =============================================================
// FILE: lib/screens/teacher_assistant/student_roster_screen.dart (UPDATED)
// =============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/models.dart';
import 'attendance_tracker_screen.dart';
import 'score_entry_screen.dart';
import 'student_report_screen.dart'; // <-- NEW IMPORT

class StudentRosterScreen extends StatelessWidget {
  final ClassSection classSection;

  const StudentRosterScreen({super.key, required this.classSection});

  Future<void> _showAddStudentDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Student'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Student\'s Full Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the student\'s name.';
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final studentsBox = Hive.box<Student>('students');
                  final newStudent = Student(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    fullName: nameController.text.trim(),
                    classSectionId: classSection.id,
                    dateOfBirth: DateTime.now(),
                    gender: 'Not Specified',
                  );
                  studentsBox.add(newStudent);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(classSection.name),
        actions: [
          ValueListenableBuilder(
              valueListenable: Hive.box<Student>('students').listenable(),
              builder: (context, Box<Student> box, _) {
                final studentsInClass = box.values
                    .where((s) => s.classSectionId == classSection.id)
                    .toList();
                if (studentsInClass.isEmpty) return const SizedBox.shrink();

                return IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AttendanceTrackerScreen(
                          classSection: classSection,
                          students: studentsInClass,
                        ),
                      ),
                    );
                  },
                  tooltip: 'Take Attendance',
                );
              }
          ),
          IconButton(
            icon: const Icon(Icons.assignment_turned_in),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ScoreEntryScreen(classSection: classSection),
                ),
              );
            },
            tooltip: 'Enter Scores',
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Student>('students').listenable(),
        builder: (context, Box<Student> box, _) {
          final studentsInClass = box.values
              .where((student) => student.classSectionId == classSection.id)
              .toList();

          if (studentsInClass.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No Students Found',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the + button to add the first student.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: studentsInClass.length,
            itemBuilder: (context, index) {
              final student = studentsInClass[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.indigo[100],
                    child: Text(
                      student.fullName.isNotEmpty ? student.fullName[0] : '?',
                      style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(student.fullName),
                  subtitle: Text('ID: ${student.id}'),
                  onTap: () {
                    // --- NAVIGATION IS NOW ACTIVE ---
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentReportScreen(student: student),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddStudentDialog(context),
        tooltip: 'Add Student',
        child: const Icon(Icons.add),
      ),
    );
  }
}