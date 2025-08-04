// =============================================================
// FILE: lib/screens/teacher_assistant/student_report_screen.dart (NEW FILE)
// =============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/models.dart';
import 'package:collection/collection.dart'; // For grouping

class StudentReportScreen extends StatelessWidget {
  final Student student;

  const StudentReportScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final scoresBox = Hive.box<Score>('scores');
    final subjectsBox = Hive.box<Subject>('subjects');
    final attendanceBox = Hive.box<AttendanceRecord>('attendance_records');

    // Filter data for the specific student
    final studentScores = scoresBox.values.where((s) => s.studentId == student.id).toList();
    final studentAttendance = attendanceBox.values.where((a) => a.studentId == student.id).toList();

    // Group scores by subjectId
    final scoresBySubject = groupBy(studentScores, (Score s) => s.subjectId);

    // Calculate attendance summary
    final presentCount = studentAttendance.where((a) => a.status == 'Present').length;
    final absentCount = studentAttendance.where((a) => a.status == 'Absent').length;
    final lateCount = studentAttendance.where((a) => a.status == 'Late').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(student.fullName),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // --- Student Info Card ---
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Student ID: ${student.id}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- Academic Performance Section ---
          Text('Academic Performance', style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          if (scoresBySubject.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Center(child: Text('No scores recorded yet.')),
            )
          else
            ...scoresBySubject.entries.map((entry) {
              final subjectId = entry.key;
              final scores = entry.value;
              final subject = subjectsBox.values.firstWhere((s) => s.id == subjectId, orElse: () => Subject(id: '', name: 'Unknown Subject', teacherId: ''));

              // Calculate average for the subject
              final totalMarks = scores.fold<double>(0, (sum, item) => sum + item.marks);
              final average = scores.isNotEmpty ? totalMarks / scores.length : 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: ExpansionTile(
                  title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Average: ${average.toStringAsFixed(2)}'),
                  children: scores.map((score) {
                    return ListTile(
                      title: Text(score.assessmentType),
                      trailing: Text(score.marks.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                ),
              );
            }),

          const SizedBox(height: 24),

          // --- Attendance Summary Section ---
          Text('Attendance Summary', style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttendanceStat('Present', presentCount, Colors.green),
                  _buildAttendanceStat('Absent', absentCount, Colors.red),
                  _buildAttendanceStat('Late', lateCount, Colors.orange),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(title),
      ],
    );
  }
}
