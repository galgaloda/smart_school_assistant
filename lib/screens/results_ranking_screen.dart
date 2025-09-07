import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/models.dart';

class ResultsRankingScreen extends StatefulWidget {
  const ResultsRankingScreen({super.key});

  @override
  State<ResultsRankingScreen> createState() => _ResultsRankingScreenState();
}

class _ResultsRankingScreenState extends State<ResultsRankingScreen> {
  String _selectedClassId = '';
  String _selectedSubjectId = '';
  String _selectedSemesterId = '';

  Map<String, double> _studentGrades = {};
  List<Map<String, dynamic>> _rankings = [];

  @override
  void initState() {
    super.initState();
    _calculateResults();
  }

  void _calculateResults() {
    if (_selectedClassId.isEmpty || _selectedSubjectId.isEmpty || _selectedSemesterId.isEmpty) {
      setState(() {
        _studentGrades = {};
        _rankings = [];
      });
      return;
    }

    final studentsBox = Hive.box<Student>('students');
    final assessmentsBox = Hive.box<Assessment>('assessments');
    final scoresBox = Hive.box<AssessmentScore>('assessment_scores');

    // Get all students in the selected class
    final students = studentsBox.values
        .where((student) => student.classSectionId == _selectedClassId)
        .toList();

    // Get all assessments for the selected subject, class, and semester
    final assessments = assessmentsBox.values
        .where((assessment) =>
            assessment.subjectId == _selectedSubjectId &&
            assessment.classSectionId == _selectedClassId &&
            assessment.semesterId == _selectedSemesterId)
        .toList();

    Map<String, double> grades = {};
    List<Map<String, dynamic>> rankings = [];

    for (final student in students) {
      double totalWeightedScore = 0;
      double totalWeight = 0;

      for (final assessment in assessments) {
        final score = scoresBox.values.firstWhere(
          (s) => s.studentId == student.id && s.assessmentId == assessment.id,
          orElse: () => AssessmentScore(
            id: '',
            studentId: '',
            assessmentId: '',
            marksObtained: 0,
            dateRecorded: DateTime.now(),
            recordedBy: '',
          ),
        );

        if (score.id.isNotEmpty) {
          final percentage = (score.marksObtained / assessment.maxMarks) * 100;
          totalWeightedScore += (percentage * assessment.weight);
          totalWeight += assessment.weight;
        }
      }

      final finalGrade = totalWeight > 0 ? (totalWeightedScore / totalWeight).toDouble() : 0.0;
      grades[student.id] = finalGrade;

      rankings.add({
        'student': student,
        'grade': finalGrade,
        'totalWeightedScore': totalWeightedScore,
        'totalWeight': totalWeight,
      });
    }

    // Sort rankings by grade (highest first)
    rankings.sort((a, b) => b['grade'].compareTo(a['grade']));

    // Add rank positions
    for (int i = 0; i < rankings.length; i++) {
      rankings[i]['rank'] = i + 1;
    }

    setState(() {
      _studentGrades = grades;
      _rankings = rankings;
    });
  }

  String _getGradeLetter(double grade) {
    if (grade >= 90) return 'A';
    if (grade >= 80) return 'B';
    if (grade >= 70) return 'C';
    if (grade >= 60) return 'D';
    return 'F';
  }

  Color _getGradeColor(double grade) {
    if (grade >= 90) return Colors.green;
    if (grade >= 80) return Colors.blue;
    if (grade >= 70) return Colors.yellow.shade700;
    if (grade >= 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Results & Rankings'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filters Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              children: [
                ValueListenableBuilder(
                  valueListenable: Hive.box<ClassSection>('class_sections').listenable(),
                  builder: (context, Box<ClassSection> classBox, _) {
                    final classes = classBox.values.toList();
                    return DropdownButtonFormField<String>(
                      value: _selectedClassId.isEmpty ? null : _selectedClassId,
                      decoration: const InputDecoration(
                        labelText: 'Select Class',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: classes.map((classSection) {
                        return DropdownMenuItem(
                          value: classSection.id,
                          child: Text(classSection.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedClassId = value ?? '';
                          _calculateResults();
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder(
                  valueListenable: Hive.box<Subject>('subjects').listenable(),
                  builder: (context, Box<Subject> subjectBox, _) {
                    final subjects = subjectBox.values.toList();
                    return DropdownButtonFormField<String>(
                      value: _selectedSubjectId.isEmpty ? null : _selectedSubjectId,
                      decoration: const InputDecoration(
                        labelText: 'Select Subject',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: subjects.map((subject) {
                        return DropdownMenuItem(
                          value: subject.id,
                          child: Text(subject.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubjectId = value ?? '';
                          _calculateResults();
                        });
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                ValueListenableBuilder(
                  valueListenable: Hive.box<Semester>('semesters').listenable(),
                  builder: (context, Box<Semester> semesterBox, _) {
                    final semesters = semesterBox.values.toList();
                    return DropdownButtonFormField<String>(
                      value: _selectedSemesterId.isEmpty ? null : _selectedSemesterId,
                      decoration: const InputDecoration(
                        labelText: 'Select Semester',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: semesters.map((semester) {
                        return DropdownMenuItem(
                          value: semester.id,
                          child: Text('${semester.name} - ${semester.academicYear}'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSemesterId = value ?? '';
                          _calculateResults();
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Results Summary
          if (_rankings.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.green.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'Total Students: ${_rankings.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Average: ${(_rankings.fold<double>(0, (sum, r) => sum + r['grade']) / _rankings.length).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Rankings List
          Expanded(
            child: _rankings.isEmpty
                ? const Center(
                    child: Text('Select class, subject, and semester to view results'),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: _rankings.length,
                    itemBuilder: (context, index) {
                      final ranking = _rankings[index];
                      final student = ranking['student'] as Student;
                      final grade = ranking['grade'] as double;
                      final rank = ranking['rank'] as int;

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getGradeColor(grade),
                            child: Text(
                              rank.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            student.fullName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Grade: ${grade.toStringAsFixed(1)}%'),
                              Text('Letter Grade: ${_getGradeLetter(grade)}'),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getGradeColor(grade),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${grade.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () {
                            // Show detailed breakdown
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('${student.fullName} - Detailed Results'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Rank: #$rank'),
                                      Text('Final Grade: ${grade.toStringAsFixed(1)}%'),
                                      Text('Letter Grade: ${_getGradeLetter(grade)}'),
                                      const SizedBox(height: 16),
                                      const Text('Assessment Breakdown:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      // TODO: Show individual assessment scores
                                      const Text('Assessment details will be shown here'),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}