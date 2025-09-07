import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/models.dart';

class AssessmentCustomizationScreen extends StatefulWidget {
  const AssessmentCustomizationScreen({super.key});

  @override
  State<AssessmentCustomizationScreen> createState() => _AssessmentCustomizationScreenState();
}

class _AssessmentCustomizationScreenState extends State<AssessmentCustomizationScreen> {
  String _selectedClassId = '';
  String _selectedSubjectId = '';
  String _selectedSemesterId = '';

  Future<void> _showAddAssessmentDialog(BuildContext context) async {
    if (_selectedClassId.isEmpty || _selectedSubjectId.isEmpty || _selectedSemesterId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select class, subject, and semester first')),
      );
      return;
    }

    final TextEditingController nameController = TextEditingController();
    final TextEditingController weightController = TextEditingController();
    final TextEditingController maxMarksController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    DateTime dueDate = DateTime.now().add(const Duration(days: 30));

    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Assessment'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Assessment Name',
                      hintText: 'e.g., Quiz 1, Mid-term, Final Exam',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter assessment name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (%)',
                      hintText: 'e.g., 20 for 20%',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter weight';
                      }
                      final weight = double.tryParse(value);
                      if (weight == null || weight <= 0 || weight > 100) {
                        return 'Please enter a valid weight (1-100)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: maxMarksController,
                    decoration: const InputDecoration(
                      labelText: 'Maximum Marks',
                      hintText: 'e.g., 20, 100',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter maximum marks';
                      }
                      final maxMarks = double.tryParse(value);
                      if (maxMarks == null || maxMarks <= 0) {
                        return 'Please enter a valid maximum marks';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Due Date',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.calendar_today),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: dueDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() {
                              dueDate = picked;
                            });
                          }
                        },
                      ),
                    ),
                    controller: TextEditingController(
                      text: '${dueDate.day}/${dueDate.month}/${dueDate.year}',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
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
                  final assessmentsBox = Hive.box<Assessment>('assessments');
                  final newAssessment = Assessment(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                    subjectId: _selectedSubjectId,
                    classSectionId: _selectedClassId,
                    semesterId: _selectedSemesterId,
                    weight: double.parse(weightController.text.trim()) / 100, // Convert to decimal
                    maxMarks: double.parse(maxMarksController.text.trim()),
                    dueDate: dueDate,
                    description: descriptionController.text.trim(),
                  );
                  assessmentsBox.add(newAssessment);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  List<Assessment> _getFilteredAssessments(List<Assessment> assessments) {
    return assessments.where((assessment) {
      final matchesClass = _selectedClassId.isEmpty || assessment.classSectionId == _selectedClassId;
      final matchesSubject = _selectedSubjectId.isEmpty || assessment.subjectId == _selectedSubjectId;
      final matchesSemester = _selectedSemesterId.isEmpty || assessment.semesterId == _selectedSemesterId;
      return matchesClass && matchesSubject && matchesSemester;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assessment Customization'),
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
                          _selectedSubjectId = ''; // Reset subject when class changes
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
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Assessments List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: Hive.box<Assessment>('assessments').listenable(),
              builder: (context, Box<Assessment> box, _) {
                final allAssessments = box.values.toList();
                final filteredAssessments = _getFilteredAssessments(allAssessments);

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.green.shade50,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Assessments: ${filteredAssessments.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Total Weight: ${(filteredAssessments.fold<double>(0, (sum, a) => sum + a.weight) * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filteredAssessments.isEmpty
                          ? const Center(
                              child: Text('No assessments found. Select filters and tap + to add one.'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(8.0),
                              itemCount: filteredAssessments.length,
                              itemBuilder: (context, index) {
                                final assessment = filteredAssessments[index];
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue,
                                      child: Text(
                                        '${(assessment.weight * 100).toInt()}%',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      assessment.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Max Marks: ${assessment.maxMarks}'),
                                        Text('Due: ${assessment.dueDate.day}/${assessment.dueDate.month}/${assessment.dueDate.year}'),
                                        if (assessment.description.isNotEmpty)
                                          Text('Description: ${assessment.description}'),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () {
                                            // TODO: Implement edit functionality
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Edit functionality - Coming Soon')),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: const Text('Delete Assessment'),
                                                content: Text('Are you sure you want to delete "${assessment.name}"?'),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.of(context).pop(),
                                                    child: const Text('Cancel'),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      assessment.delete();
                                                      Navigator.of(context).pop();
                                                    },
                                                    child: const Text('Delete'),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAssessmentDialog(context),
        tooltip: 'Add Assessment',
        child: const Icon(Icons.add),
      ),
    );
  }
}