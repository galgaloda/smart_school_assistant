//=============================================================
// FILE: lib/screens/teacher_assistant/score_entry_screen.dart (NEW FILE)
// =============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/models.dart';

class ScoreEntryScreen extends StatefulWidget {
  final ClassSection classSection;

  const ScoreEntryScreen({super.key, required this.classSection});

  @override
  State<ScoreEntryScreen> createState() => _ScoreEntryScreenState();
}

class _ScoreEntryScreenState extends State<ScoreEntryScreen> {
  Student? _selectedStudent;
  Subject? _selectedSubject;
  Assessment? _selectedAssessment;
  Semester? _selectedSemester;
  final TextEditingController _scoreController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _saveScore() {
    if (_formKey.currentState!.validate()) {
      if (_selectedStudent == null || _selectedAssessment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields.'), backgroundColor: Colors.red),
        );
        return;
      }

      final marks = double.tryParse(_scoreController.text) ?? 0.0;

      // Validate marks don't exceed maximum
      if (marks > _selectedAssessment!.maxMarks) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Marks cannot exceed ${_selectedAssessment!.maxMarks}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final scoresBox = Hive.box<AssessmentScore>('assessment_scores');
      final newScore = AssessmentScore(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        studentId: _selectedStudent!.id,
        assessmentId: _selectedAssessment!.id,
        marksObtained: marks,
        dateRecorded: DateTime.now(),
        recordedBy: 'Teacher', // In a real app, this would be the current user
      );
      scoresBox.add(newScore);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Score saved successfully!'), backgroundColor: Colors.green),
      );

      // Clear fields after saving
      setState(() {
        _scoreController.clear();
        _selectedAssessment = null;
      });
    }
  }

@override
Widget build(BuildContext context) {
  final studentsInClass = Hive.box<Student>('students').values
      .where((s) => s.classSectionId == widget.classSection.id)
      .toList();
  final allSubjects = Hive.box<Subject>('subjects').values.toList();

  return Scaffold(
    appBar: AppBar(
      title: const Text('Enter Student Scores'),
      backgroundColor: Colors.indigo,
      foregroundColor: Colors.white,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            // Student Dropdown
            DropdownButtonFormField<Student>(
              value: _selectedStudent,
              decoration: const InputDecoration(
                labelText: 'Select a Student',
                border: OutlineInputBorder(),
              ),
              items: studentsInClass.map((student) {
                return DropdownMenuItem(value: student, child: Text(student.fullName));
              }).toList(),
              onChanged: (value) => setState(() => _selectedStudent = value),
              validator: (value) => value == null ? 'Please select a student.' : null,
            ),
            const SizedBox(height: 16),

            // Subject Dropdown
            DropdownButtonFormField<Subject>(
              value: _selectedSubject,
              decoration: const InputDecoration(
                labelText: 'Select a Subject',
                border: OutlineInputBorder(),
              ),
              items: allSubjects.map((subject) {
                return DropdownMenuItem(value: subject, child: Text(subject.name));
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                  _selectedAssessment = null; // Reset assessment when subject changes
                });
              },
              validator: (value) => value == null ? 'Please select a subject.' : null,
            ),
            const SizedBox(height: 16),

            // Semester Dropdown
            ValueListenableBuilder(
              valueListenable: Hive.box<Semester>('semesters').listenable(),
              builder: (context, Box<Semester> semesterBox, _) {
                final semesters = semesterBox.values.toList();
                return DropdownButtonFormField<Semester>(
                  value: _selectedSemester,
                  decoration: const InputDecoration(
                    labelText: 'Select Semester',
                    border: OutlineInputBorder(),
                  ),
                  items: semesters.map((semester) {
                    return DropdownMenuItem(
                      value: semester,
                      child: Text('${semester.name} - ${semester.academicYear}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSemester = value;
                      _selectedAssessment = null; // Reset assessment when semester changes
                    });
                  },
                  validator: (value) => value == null ? 'Please select a semester.' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // Assessment Dropdown (filtered by subject and semester)
            ValueListenableBuilder(
              valueListenable: Hive.box<Assessment>('assessments').listenable(),
              builder: (context, Box<Assessment> assessmentBox, _) {
                final assessments = assessmentBox.values.where((assessment) {
                  return assessment.subjectId == _selectedSubject?.id &&
                         assessment.classSectionId == widget.classSection.id &&
                         assessment.semesterId == _selectedSemester?.id;
                }).toList();

                return DropdownButtonFormField<Assessment>(
                  value: _selectedAssessment,
                  decoration: const InputDecoration(
                    labelText: 'Select Assessment',
                    border: OutlineInputBorder(),
                  ),
                  items: assessments.map((assessment) {
                    return DropdownMenuItem(
                      value: assessment,
                      child: Text('${assessment.name} (${(assessment.weight * 100).toStringAsFixed(0)}%)'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedAssessment = value),
                  validator: (value) => value == null ? 'Please select an assessment.' : null,
                );
              },
            ),
            const SizedBox(height: 16),

            // Assessment Info (if selected)
            if (_selectedAssessment != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assessment: ${_selectedAssessment!.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Weight: ${(_selectedAssessment!.weight * 100).toStringAsFixed(0)}%'),
                    Text('Max Marks: ${_selectedAssessment!.maxMarks}'),
                    if (_selectedAssessment!.description.isNotEmpty)
                      Text('Description: ${_selectedAssessment!.description}'),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Score Input
            TextFormField(
              controller: _scoreController,
              decoration: InputDecoration(
                labelText: 'Score / Marks (Max: ${_selectedAssessment?.maxMarks ?? "N/A"})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a score.';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number.';
                }
                final score = double.parse(value);
                if (_selectedAssessment != null && score > _selectedAssessment!.maxMarks) {
                  return 'Score cannot exceed ${_selectedAssessment!.maxMarks}';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _saveScore,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save Score'),
            ),
          ],
        ),
      ),
    ),
  );
}
}
