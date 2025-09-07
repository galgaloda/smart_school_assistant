import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/l10n/app_localizations.dart';
import 'package:smart_school_assistant/models.dart';
import 'package:smart_school_assistant/utils/ranking_service.dart';
import 'package:smart_school_assistant/utils/transliteration_utils.dart';
import 'attendance_tracker_screen.dart';
import 'score_entry_screen.dart';
import 'student_report_screen.dart';
import '../photo_upload_screen.dart';
import 'dart:io';

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
          title: Text(AppLocalizations.of(context)!.addNewStudent),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.studentFullName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context)!.pleaseEnterStudentName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    final transliterated = TransliterationUtils.transliterateOromoToAmharic(nameController.text);
                    nameController.text = transliterated;
                  },
                  child: const Text('Transliterate to Amharic'),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.save),
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
    return ValueListenableBuilder(
      valueListenable: Hive.box<Student>('students').listenable(),
      builder: (context, studentBox, _) {
        return ValueListenableBuilder(
          valueListenable: Hive.box<Score>('scores').listenable(),
          builder: (context, scoreBox, __) {
            final rankedStudents = RankingService.getRankedStudents(classSection.id);

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
                          tooltip: AppLocalizations.of(context)!.takeAttendance,
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
                    tooltip: AppLocalizations.of(context)!.enterScores,
                  ),
                ],
              ),
              body: rankedStudents.isEmpty
                  ? Center(
               child: Text(AppLocalizations.of(context)!.noStudentsFound),
             )
                  : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: rankedStudents.length,
                itemBuilder: (context, index) {
                  final studentRank = rankedStudents[index];
                  final student = studentRank.student;

                  return Card(
                    child: ListTile(
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.indigo[100],
                            backgroundImage: student.photoPath != null
                                ? FileImage(File(student.photoPath!))
                                : null,
                            child: student.photoPath == null
                                ? Text(
                                    studentRank.rank.toString(),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, color: Colors.indigo),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.indigo, width: 1),
                              ),
                              child: Icon(
                                student.photoPath != null ? Icons.photo_camera : Icons.add_a_photo,
                                size: 10,
                                color: Colors.indigo,
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: Text(student.fullName),
                      subtitle: Text('Average: ${studentRank.average.toStringAsFixed(2)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.photo_camera, size: 20),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PhotoUploadScreen(student: student),
                                ),
                              );
                            },
                            tooltip: 'Manage Photo',
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => StudentReportScreen(
                              student: student,
                              classRank: studentRank,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => _showAddStudentDialog(context),
                tooltip: AppLocalizations.of(context)!.addNewStudent,
                child: const Icon(Icons.add),
              ),
            );
          },
        );
      },
    );
  }
}