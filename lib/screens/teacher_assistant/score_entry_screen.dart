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
String? _selectedAssessmentType;
final TextEditingController _scoreController = TextEditingController();
final _formKey = GlobalKey<FormState>();

final List<String> _assessmentTypes = ['Homework', 'Quiz', 'Mid-term', 'Final Exam', 'Project'];

void _saveScore() {
if (_formKey.currentState!.validate()) {
if (_selectedStudent == null || _selectedSubject == null || _selectedAssessmentType == null) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Please fill all fields.'), backgroundColor: Colors.red),
);
return;
}

final scoresBox = Hive.box<Score>('scores');
final newScore = Score(
studentId: _selectedStudent!.id,
subjectId: _selectedSubject!.id,
assessmentType: _selectedAssessmentType!,
marks: double.tryParse(_scoreController.text) ?? 0.0,
date: DateTime.now(),
);
scoresBox.add(newScore);

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Score saved successfully!'), backgroundColor: Colors.green),
);

// Clear fields after saving
setState(() {
_scoreController.clear();
});
}
}

@override
Widget build(BuildContext context) {
final studentsInClass = Hive.box<Student>('students').values.where((s) => s.classSectionId == widget.classSection.id).toList();
final allSubjects = Hive.box<Subject>('subjects').values.toList();

return Scaffold(
appBar: AppBar(
title: const Text('Enter Student Scores'),
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
hint: const Text('Select a Student'),
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
hint: const Text('Select a Subject'),
items: allSubjects.map((subject) {
return DropdownMenuItem(value: subject, child: Text(subject.name));
}).toList(),
onChanged: (value) => setState(() => _selectedSubject = value),
validator: (value) => value == null ? 'Please select a subject.' : null,
),
const SizedBox(height: 16),

// Assessment Type Dropdown
DropdownButtonFormField<String>(
value: _selectedAssessmentType,
hint: const Text('Select Assessment Type'),
items: _assessmentTypes.map((type) {
return DropdownMenuItem(value: type, child: Text(type));
}).toList(),
onChanged: (value) => setState(() => _selectedAssessmentType = value),
validator: (value) => value == null ? 'Please select an assessment type.' : null,
),
const SizedBox(height: 16),

// Score Input
TextFormField(
controller: _scoreController,
decoration: const InputDecoration(
labelText: 'Score / Marks',
border: OutlineInputBorder(),
),
keyboardType: TextInputType.number,
validator: (value) {
if (value == null || value.isEmpty) {
return 'Please enter a score.';
}
if (double.tryParse(value) == null) {
return 'Please enter a valid number.';
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
