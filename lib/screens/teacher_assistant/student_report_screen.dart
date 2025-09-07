// =============================================================
// FILE: lib/screens/teacher_assistant/student_report_screen.dart (COMPLETE)
// =============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/models.dart';
import 'package:collection/collection.dart';
import 'package:smart_school_assistant/services/pdf_service.dart';
import 'package:smart_school_assistant/screens/reports/pdf_preview_screen.dart';
import 'package:smart_school_assistant/utils/ranking_service.dart';

class StudentReportScreen extends StatefulWidget {
  final Student student;
  final StudentRank? classRank;

  const StudentReportScreen({super.key, required this.student, this.classRank});

  @override
  State<StudentReportScreen> createState() => _StudentReportScreenState();
}

class _StudentReportScreenState extends State<StudentReportScreen> {
  late StudentRank _studentRank;

  @override
  void initState() {
    super.initState();
    if (widget.classRank == null) {
      final rankedList = RankingService.getRankedStudents(widget.student.classSectionId);
      _studentRank = rankedList.firstWhere(
            (r) => r.student.id == widget.student.id,
        orElse: () => StudentRank(student: widget.student, average: 0, rank: 0),
      );
    } else {
      _studentRank = widget.classRank!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoresBox = Hive.box<Score>('scores');
    final subjectsBox = Hive.box<Subject>('subjects');
    final attendanceBox = Hive.box<AttendanceRecord>('attendance_records');

    final studentScores = scoresBox.values.where((s) => s.studentId == widget.student.id).toList();
    final studentAttendance = attendanceBox.values.where((a) => a.studentId == widget.student.id).toList();
    final scoresBySubject = groupBy(studentScores, (Score s) => s.subjectId);
    final presentCount = studentAttendance.where((a) => a.status == 'Present').length;
    final absentCount = studentAttendance.where((a) => a.status == 'Absent').length;
    final lateCount = studentAttendance.where((a) => a.status == 'Late').length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Generating PDF...')),
              );
              final pdfFile = await PdfApiService.generateStudentReport(widget.student, _studentRank);
              if (!mounted) return;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PdfPreviewScreen(pdfFile: pdfFile),
                ),
              );
            },
            tooltip: 'Generate PDF Report',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.student.fullName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('Student ID: ${widget.student.id}'),
                  const SizedBox(height: 8),
                  Text(
                    'Overall Average: ${_studentRank.average.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Class Rank: ${_studentRank.rank}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
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
