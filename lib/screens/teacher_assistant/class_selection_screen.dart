// =============================================================
// FILE: lib/screens/teacher_assistant/class_selection_screen.dart (FIXED & COMPLETE)
// =============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/models.dart';
import 'student_roster_screen.dart';
import 'manage_subjects_screen.dart';

class ClassSelectionScreen extends StatelessWidget {
  const ClassSelectionScreen({super.key});

  Future<void> _showAddClassDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Class Section'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Class Name (e.g., Grade 7A)',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a class name.';
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
                  final classBox = Hive.box<ClassSection>('class_sections');
                  final newClass = ClassSection(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text.trim(),
                  );
                  classBox.add(newClass);
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
        title: const Text('Select a Class'),
        actions: [
          IconButton(
            icon: const Icon(Icons.book),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ManageSubjectsScreen()),
              );
            },
            tooltip: 'Manage Subjects',
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<ClassSection>('class_sections').listenable(),
        builder: (context, Box<ClassSection> box, _) {
          if (box.values.isEmpty) {
            return const Center(
              child: Text('No classes found. Tap + to add one.'),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: box.values.length,
            itemBuilder: (context, index) {
              final classSection = box.getAt(index)!;
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.class_, color: Colors.indigo),
                  title: Text(classSection.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentRosterScreen(classSection: classSection),
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
        onPressed: () => _showAddClassDialog(context),
        tooltip: 'Add Class',
        child: const Icon(Icons.add),
      ),
    );
  }
}