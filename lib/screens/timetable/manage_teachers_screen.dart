// =============================================================
// FILE: lib/screens/timetable/manage_teachers_screen.dart (UPDATED)
// =============================================================
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_school_assistant/l10n/app_localizations.dart';
import 'package:smart_school_assistant/models.dart';

class ManageTeachersScreen extends StatelessWidget {
  const ManageTeachersScreen({super.key});

  Future<void> _showAddTeacherDialog(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.addNewTeacher),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.teachersFullName,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return AppLocalizations.of(context)!.pleaseEnterTeacherName;
                }
                return null;
              },
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.save),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final teachersBox = Hive.box<Teacher>('teachers');
                  final newTeacher = Teacher(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    fullName: nameController.text.trim(),
                  );
                  teachersBox.add(newTeacher);
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
        title: Text(AppLocalizations.of(context)!.manageTeachers),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Teacher>('teachers').listenable(),
        builder: (context, Box<Teacher> box, _) {
          if (box.values.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context)!.noTeachersFound),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: box.values.length,
            itemBuilder: (context, index) {
              final teacher = box.getAt(index)!;
              return Card(
                child: ListTile(
                  title: Text(teacher.fullName),
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
        onPressed: () => _showAddTeacherDialog(context),
        tooltip: AppLocalizations.of(context)!.addTeacher,
        child: const Icon(Icons.add),
      ),
    );
  }
}
