// =============================================================
// FILE: lib/screens/timetable/manage_timetable_subjects_screen.dart (ENHANCED)
// =============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/models.dart';

class ManageTimetableSubjectsScreen extends StatelessWidget {
  const ManageTimetableSubjectsScreen({super.key});

  Future<void> _showAddSubjectDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    Teacher? selectedTeacher;

    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Subject'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Subject Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a subject name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    ValueListenableBuilder<Box<Teacher>>(
                      valueListenable: Hive.box<Teacher>('teachers').listenable(),
                      builder: (context, box, _) {
                        final teachers = box.values.toList();
                        return DropdownButtonFormField<Teacher>(
                          hint: const Text('Assign a Teacher'),
                          value: selectedTeacher,
                          items: teachers.map((teacher) {
                            return DropdownMenuItem(
                              value: teacher,
                              child: Text(teacher.fullName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedTeacher = value;
                            });
                          },
                          validator: (value) => value == null ? 'Please assign a teacher.' : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                ElevatedButton(
                  child: const Text('Save'),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      final subjectsBox = Hive.box<Subject>('subjects');
                      final newSubject = Subject(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: nameController.text.trim(),
                        teacherId: selectedTeacher!.id,
                      );
                      subjectsBox.add(newSubject);
                      Navigator.of(dialogContext).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Subjects & Teachers'),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Subject>('subjects').listenable(),
        builder: (context, Box<Subject> box, _) {
          final teachersBox = Hive.box<Teacher>('teachers');
          if (box.values.isEmpty) {
            return const Center(
              child: Text('No subjects found. Tap + to add one.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: box.values.length,
            itemBuilder: (context, index) {
              final subject = box.getAt(index)!;
              final teacher = teachersBox.values.firstWhere(
                    (t) => t.id == subject.teacherId,
                orElse: () => Teacher(id: '', fullName: 'Not Assigned'),
              );
              return Card(
                child: ListTile(
                  title: Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Teacher: ${teacher.fullName}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => box.deleteAt(index),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubjectDialog(context),
        tooltip: 'Add Subject',
        child: const Icon(Icons.add),
      ),
    );
  }
}
